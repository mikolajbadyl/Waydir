import 'dart:io';

import '../platform/platform_paths.dart';
import '../platform/win32_attributes.dart';
import '../settings/settings_store.dart';
import 'app_entry.dart';
import 'app_resolver.dart';
import 'mime_resolver.dart';

export 'app_entry.dart' show AppEntry;
export 'app_resolver.dart' show SetDefaultUnsupported;
export 'mime_resolver.dart' show MimeType;

/// Facade for file-type detection and "Open / Open With" behaviour.
///
/// Resolvers are constructed lazily and cached for the process lifetime.
class OpenService {
  OpenService._();

  static final MimeResolver _mime = MimeResolver.platform();
  static final AppResolver _apps = AppResolver.platform();

  /// Opens [path] with the system default handler. Behaviour-compatible with
  /// the previous `xdg-open`/`open`/shell-open implementation.
  static Future<void> openDefault(String path) async {
    if (PlatformPaths.isWindows) {
      shellOpenOnWindows(path);
    } else if (Platform.isLinux) {
      await Process.start('xdg-open', [path], mode: ProcessStartMode.detached);
    } else if (Platform.isMacOS) {
      await Process.start('open', [path], mode: ProcessStartMode.detached);
    }
  }

  static Future<MimeType> mimeOf(String path) => _mime.resolve(path);

  /// Apps to show in the "Open With" submenu for [path]: recently used first,
  /// then associated apps, deduplicated.
  static Future<OpenWithOptions> optionsFor(String path) async {
    final mime = await _mime.resolve(path);
    final associated = await _apps.appsFor(mime, path);
    final recent = await _recentFor(mime, associated);
    final canSetDefault = await _apps.canSetDefault();
    return OpenWithOptions(
      mime: mime,
      recent: recent,
      associated: associated,
      canSetDefault: canSetDefault,
    );
  }

  static Future<List<AppEntry>> allApps() => _apps.allApps();

  static Future<void> openWith(AppEntry app, List<String> paths) async {
    await _apps.launch(app, paths);
    if (paths.isNotEmpty) {
      final mime = await _mime.resolve(paths.first);
      await _recordRecent(mime, app);
    }
  }

  static Future<void> setDefaultApp(AppEntry app, MimeType mime) =>
      _apps.setDefault(app, mime);

  static Future<bool> canSetDefault() => _apps.canSetDefault();

  /// Opens the native "Open with…" chooser. Implemented on Windows; on other
  /// platforms there is no system equivalent and this is a no-op.
  static Future<void> systemOpenWithDialog(String path) async {
    if (!Platform.isWindows) return;
    await Process.start('rundll32.exe', [
      'shell32.dll,OpenAs_RunDLL',
      path,
    ], mode: ProcessStartMode.detached);
  }

  static Future<List<AppEntry>> _recentFor(
    MimeType mime,
    List<AppEntry> associated,
  ) async {
    try {
      final rows = await SettingsStore.instance.db.getRecentApps(mime.value);
      return rows
          .map(
            (r) => AppEntry(
              id: r.appId,
              name: r.appName,
              exec: r.appExec,
              iconPath: r.iconPath,
            ),
          )
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<void> _recordRecent(MimeType mime, AppEntry app) async {
    try {
      await SettingsStore.instance.db.recordRecentApp(
        mime: mime.value,
        appId: app.id,
        appName: app.name,
        appExec: app.exec,
        iconPath: app.iconPath,
      );
    } catch (_) {}
  }
}

class OpenWithOptions {
  final MimeType mime;
  final List<AppEntry> recent;
  final List<AppEntry> associated;
  final bool canSetDefault;

  const OpenWithOptions({
    required this.mime,
    required this.recent,
    required this.associated,
    required this.canSetDefault,
  });

  AppEntry? get defaultApp {
    for (final a in associated) {
      if (a.isDefault) return a;
    }
    return null;
  }

  bool get isEmpty => recent.isEmpty && associated.isEmpty;
}
