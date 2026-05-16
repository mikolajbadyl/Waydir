import 'dart:io';

import 'package:path/path.dart' as p;

import 'app_entry.dart';
import 'desktop_entry.dart';
import 'icon_resolver.dart';
import 'mime_resolver.dart';

/// Thrown by [AppResolver.setDefault] when the platform cannot set a default
/// programmatically (e.g. macOS without `duti`, or Windows' protected
/// UserChoice). UI surfaces this as a disabled/explained control.
class SetDefaultUnsupported implements Exception {
  final String reason;
  const SetDefaultUnsupported(this.reason);
  @override
  String toString() => reason;
}

/// Platform abstraction for discovering and launching applications that can
/// open a given file type.
abstract class AppResolver {
  /// Applications associated with [mime]/[path], default first.
  Future<List<AppEntry>> appsFor(MimeType mime, String path);

  /// All launchable applications on the system, for the "choose another
  /// application" case. May be empty when enumeration is unsupported.
  Future<List<AppEntry>> allApps();

  Future<AppEntry?> defaultFor(MimeType mime, String path);

  /// Launches [app] with [paths]. Detached; never blocks the UI.
  Future<void> launch(AppEntry app, List<String> paths);

  /// Makes [app] the default handler for [mime]. Throws
  /// [SetDefaultUnsupported] when not possible on this platform.
  Future<void> setDefault(AppEntry app, MimeType mime);

  /// True when [setDefault] can work on this platform/environment.
  Future<bool> canSetDefault();

  factory AppResolver.platform() {
    if (Platform.isLinux) return LinuxAppResolver();
    if (Platform.isMacOS) return MacAppResolver();
    if (Platform.isWindows) return WindowsAppResolver();
    return _NullAppResolver();
  }
}

class _NullAppResolver implements AppResolver {
  @override
  Future<List<AppEntry>> appsFor(MimeType mime, String path) async => [];
  @override
  Future<List<AppEntry>> allApps() async => [];
  @override
  Future<AppEntry?> defaultFor(MimeType mime, String path) async => null;
  @override
  Future<void> launch(AppEntry app, List<String> paths) async {}
  @override
  Future<void> setDefault(AppEntry app, MimeType mime) async =>
      throw const SetDefaultUnsupported('Unsupported platform');
  @override
  Future<bool> canSetDefault() async => false;
}

// ───────────────────────────── Linux ──────────────────────────────

class LinuxAppResolver implements AppResolver {
  List<_LinuxApp>? _cache;

  List<String> get _appDirs {
    final dirs = <String>[];
    final dataHome = Platform.environment['XDG_DATA_HOME'];
    dirs.add(
      (dataHome != null && dataHome.isNotEmpty)
          ? dataHome
          : p.join(Platform.environment['HOME'] ?? '', '.local', 'share'),
    );
    final dataDirs = Platform.environment['XDG_DATA_DIRS'];
    dirs.addAll(
      (dataDirs != null && dataDirs.isNotEmpty)
          ? dataDirs.split(':')
          : ['/usr/local/share', '/usr/share'],
    );
    return dirs.map((d) => p.join(d, 'applications')).toList();
  }

  Future<List<_LinuxApp>> _scan() async {
    if (_cache != null) return _cache!;
    final apps = <String, _LinuxApp>{};
    for (final dir in _appDirs) {
      final d = Directory(dir);
      if (!d.existsSync()) continue;
      await for (final f in d.list(recursive: true, followLinks: false)) {
        if (f is! File || !f.path.endsWith('.desktop')) continue;
        final id = p
            .relative(f.path, from: dir)
            .replaceAll(Platform.pathSeparator, '-');
        if (apps.containsKey(id)) continue; // earlier dirs win
        try {
          final entry = DesktopEntry.parse(await f.readAsString());
          if (entry == null || !entry.isLaunchable) continue;
          apps[id] = _LinuxApp(id, entry);
        } catch (_) {}
      }
    }
    return _cache = apps.values.toList();
  }

  AppEntry _toEntry(_LinuxApp a, {bool isDefault = false}) => AppEntry(
    id: a.id,
    name: a.entry.name.isEmpty ? a.id : a.entry.name,
    exec: a.entry.exec,
    iconPath: IconResolver.instance.resolve(a.entry.icon),
    isDefault: isDefault,
  );

  @override
  Future<List<AppEntry>> appsFor(MimeType mime, String path) async {
    final all = await _scan();
    final def = await defaultFor(mime, path);
    final matches = all
        .where((a) => a.entry.mimeTypes.contains(mime.value))
        .map((a) => _toEntry(a, isDefault: a.id == def?.id))
        .toList();
    matches.sort((x, y) {
      if (x.isDefault != y.isDefault) return x.isDefault ? -1 : 1;
      return x.name.toLowerCase().compareTo(y.name.toLowerCase());
    });
    return matches;
  }

  @override
  Future<List<AppEntry>> allApps() async {
    final all = await _scan();
    final list = all
        .where((a) => !a.entry.noDisplay)
        .map((a) => _toEntry(a))
        .toList();
    list.sort((x, y) => x.name.toLowerCase().compareTo(y.name.toLowerCase()));
    return list;
  }

  @override
  Future<AppEntry?> defaultFor(MimeType mime, String path) async {
    try {
      final r = await Process.run('xdg-mime', [
        'query',
        'default',
        mime.value,
      ]);
      final id = (r.stdout as String).trim();
      if (id.isEmpty) return null;
      final all = await _scan();
      for (final a in all) {
        if (a.id == id) return _toEntry(a, isDefault: true);
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<void> launch(AppEntry app, List<String> paths) async {
    final args = DesktopEntry.expandExec(app.exec, paths);
    if (args.isEmpty) return;
    await Process.start(
      args.first,
      args.sublist(1),
      mode: ProcessStartMode.detached,
    );
  }

  @override
  Future<bool> canSetDefault() async => true;

  @override
  Future<void> setDefault(AppEntry app, MimeType mime) async {
    final r = await Process.run('xdg-mime', [
      'default',
      app.id,
      mime.value,
    ]);
    if (r.exitCode != 0) {
      throw SetDefaultUnsupported(
        (r.stderr as String).trim().isEmpty
            ? 'xdg-mime failed'
            : (r.stderr as String).trim(),
      );
    }
  }

}

class _LinuxApp {
  final String id;
  final DesktopEntry entry;
  _LinuxApp(this.id, this.entry);
}

// ───────────────────────────── macOS ──────────────────────────────

class MacAppResolver implements AppResolver {
  List<AppEntry>? _allCache;

  @override
  Future<List<AppEntry>> appsFor(MimeType mime, String path) async {
    // Launch Services has no clean CLI to enumerate handlers; offer every
    // installed app with the default (if discoverable) first, mirroring
    // Finder's "Open With ▸ Other…".
    final def = await defaultFor(mime, path);
    final all = await allApps();
    if (def == null) return all;
    return [
      def,
      ...all.where((a) => a.id != def.id),
    ];
  }

  @override
  Future<List<AppEntry>> allApps() async {
    if (_allCache != null) return _allCache!;
    final apps = <String, AppEntry>{};
    for (final dir in [
      '/Applications',
      '/System/Applications',
      p.join(Platform.environment['HOME'] ?? '', 'Applications'),
    ]) {
      final d = Directory(dir);
      if (!d.existsSync()) continue;
      for (final e in d.listSync(followLinks: false)) {
        if (e.path.endsWith('.app')) {
          final name = p.basenameWithoutExtension(e.path);
          apps[e.path] = AppEntry(id: e.path, name: name, exec: e.path);
        }
      }
    }
    final list = apps.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return _allCache = list;
  }

  @override
  Future<AppEntry?> defaultFor(MimeType mime, String path) async {
    // `duti -x` reports the default handler for a UTI when available.
    if (!await _hasDuti() || !mime.isUti) return null;
    try {
      final r = await Process.run('duti', ['-x', mime.value]);
      if (r.exitCode == 0) {
        final lines = (r.stdout as String)
            .split('\n')
            .map((l) => l.trim())
            .where((l) => l.isNotEmpty)
            .toList();
        // Last line is typically the bundle path.
        final bundle = lines.lastWhere(
          (l) => l.endsWith('.app'),
          orElse: () => '',
        );
        if (bundle.isNotEmpty) {
          return AppEntry(
            id: bundle,
            name: p.basenameWithoutExtension(bundle),
            exec: bundle,
            isDefault: true,
          );
        }
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<void> launch(AppEntry app, List<String> paths) async {
    await Process.start('open', [
      '-a',
      app.exec,
      ...paths,
    ], mode: ProcessStartMode.detached);
  }

  Future<bool> _hasDuti() async {
    try {
      final r = await Process.run('which', ['duti']);
      return r.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> canSetDefault() => _hasDuti();

  @override
  Future<void> setDefault(AppEntry app, MimeType mime) async {
    if (!await _hasDuti()) {
      throw const SetDefaultUnsupported(
        'Setting the default app on macOS requires the "duti" tool',
      );
    }
    final bundleId = await _bundleId(app.exec);
    if (bundleId == null) {
      throw const SetDefaultUnsupported('Could not read app bundle id');
    }
    final r = await Process.run('duti', [
      '-s',
      bundleId,
      mime.value,
      'all',
    ]);
    if (r.exitCode != 0) {
      throw SetDefaultUnsupported((r.stderr as String).trim());
    }
  }

  Future<String?> _bundleId(String appPath) async {
    try {
      final r = await Process.run('mdls', [
        '-name',
        'kMDItemCFBundleIdentifier',
        '-raw',
        appPath,
      ]);
      final out = (r.stdout as String).trim();
      return (out.isEmpty || out == '(null)') ? null : out;
    } catch (_) {
      return null;
    }
  }
}

// ──────────────────────────── Windows ─────────────────────────────

class WindowsAppResolver implements AppResolver {
  String _ext(String path) {
    final e = p.extension(path);
    return e.isEmpty ? '' : e; // includes leading dot
  }

  @override
  Future<List<AppEntry>> appsFor(MimeType mime, String path) async {
    final ext = _ext(path);
    final apps = <String, AppEntry>{};
    final def = await defaultFor(mime, path);
    if (def != null) apps[def.id] = def;
    if (ext.isNotEmpty) {
      for (final prog in await _openWithProgids(ext)) {
        final cmd = await _commandForProgid(prog);
        if (cmd != null) {
          apps.putIfAbsent(
            prog,
            () => AppEntry(id: prog, name: prog, exec: cmd),
          );
        }
      }
    }
    final list = apps.values.toList();
    list.sort((a, b) {
      if (a.isDefault != b.isDefault) return a.isDefault ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return list;
  }

  @override
  Future<List<AppEntry>> allApps() async => const [];

  @override
  Future<AppEntry?> defaultFor(MimeType mime, String path) async {
    final ext = _ext(path);
    if (ext.isEmpty) return null;
    final exe = await _assocQuery(ext, 'exe');
    if (exe == null || exe.isEmpty) return null;
    final name = await _assocQuery(ext, 'name') ?? p.basename(exe);
    return AppEntry(id: exe, name: name, exec: exe, isDefault: true);
  }

  @override
  Future<void> launch(AppEntry app, List<String> paths) async {
    await Process.start(app.exec, paths, mode: ProcessStartMode.detached);
  }

  @override
  Future<bool> canSetDefault() async => false;

  @override
  Future<void> setDefault(AppEntry app, MimeType mime) async {
    // Windows protects the per-user default (UserChoice hash); programmatic
    // changes are blocked by design. The system dialog is the supported path.
    throw const SetDefaultUnsupported(
      'Use the system "Open with" dialog to change the default on Windows',
    );
  }

  // Default handler lookup via shlwapi!AssocQueryStringW.
  Future<String?> _assocQuery(String ext, String which) async {
    // `assoc`/`ftype` give a robust, dependency-free path.
    try {
      final assoc = await Process.run('cmd', ['/c', 'assoc', ext]);
      final line = (assoc.stdout as String).trim(); // ".txt=txtfile"
      final eq = line.indexOf('=');
      if (eq < 0) return null;
      final progid = line.substring(eq + 1).trim();
      if (which == 'name') return progid;
      final ftype = await Process.run('cmd', ['/c', 'ftype', progid]);
      final fl = (ftype.stdout as String).trim(); // "txtfile=C:\..\notepad %1"
      final feq = fl.indexOf('=');
      if (feq < 0) return null;
      return _exeFromCommand(fl.substring(feq + 1).trim());
    } catch (_) {
      return null;
    }
  }

  Future<List<String>> _openWithProgids(String ext) async {
    try {
      final r = await Process.run('reg', [
        'query',
        'HKCR\\$ext\\OpenWithProgids',
      ]);
      if (r.exitCode != 0) return const [];
      return (r.stdout as String)
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty && !l.startsWith('HKEY'))
          .map((l) => l.split(RegExp(r'\s+')).first)
          .where((s) => s.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<String?> _commandForProgid(String progid) async {
    try {
      final r = await Process.run('reg', [
        'query',
        'HKCR\\$progid\\shell\\open\\command',
        '/ve',
      ]);
      if (r.exitCode != 0) return null;
      final m = RegExp(
        r'REG_\w+\s+(.+)',
      ).firstMatch(r.stdout as String);
      if (m == null) return null;
      return _exeFromCommand(m.group(1)!.trim());
    } catch (_) {
      return null;
    }
  }

  String? _exeFromCommand(String command) {
    var c = command.trim();
    if (c.isEmpty) return null;
    if (c.startsWith('"')) {
      final end = c.indexOf('"', 1);
      if (end > 0) return c.substring(1, end);
    }
    final space = c.indexOf(' ');
    return space < 0 ? c : c.substring(0, space);
  }
}
