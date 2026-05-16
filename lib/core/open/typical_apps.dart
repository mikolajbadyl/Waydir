import 'dart:io';

import 'package:path/path.dart' as p;

import 'app_entry.dart';

/// Built-in fallback: when the OS default handler cannot be resolved, pick a
/// well-known application that is typical for the file's category on the
/// current platform and actually installed. Keeps double-click working with a
/// concrete, named app instead of nothing.
class TypicalApps {
  TypicalApps._();

  static AppEntry? forPath(String path) {
    final cat = _categoryFor(p.extension(path).toLowerCase());
    if (cat == null) return null;
    final candidates = Platform.isWindows
        ? _windows[cat]
        : Platform.isMacOS
        ? _macos[cat]
        : _linux[cat];
    if (candidates == null) return null;
    for (final c in candidates) {
      final exec = c.resolve();
      if (exec != null) {
        return AppEntry(id: c.id, name: c.name, exec: exec, isDefault: true);
      }
    }
    return null;
  }

  static _Category? _categoryFor(String ext) {
    final e = ext.startsWith('.') ? ext.substring(1) : ext;
    if (_image.contains(e)) return _Category.image;
    if (_video.contains(e)) return _Category.video;
    if (_audio.contains(e)) return _Category.audio;
    if (e == 'pdf') return _Category.pdf;
    if (_editor.contains(e)) return _Category.editor;
    return null;
  }

  static const _image = {
    'jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'tiff', 'tif', 'ico',
    'heic', 'svg',
  };
  static const _video = {
    'mp4', 'mkv', 'avi', 'mov', 'webm', 'wmv', 'flv', 'm4v', 'mpg', 'mpeg',
  };
  static const _audio = {
    'mp3', 'wav', 'flac', 'ogg', 'm4a', 'aac', 'wma', 'opus',
  };
  static const _editor = {
    'txt', 'md', 'log', 'csv', 'json', 'xml', 'yaml', 'yml', 'ini', 'cfg',
    'conf', 'dart', 'js', 'ts', 'py', 'c', 'cpp', 'h', 'hpp', 'java', 'rs',
    'go', 'rb', 'sh', 'html', 'css',
  };

  // Linux: PATH-resolved binaries; %f makes the launcher pass the file.
  static final _linux = <_Category, List<_Candidate>>{
    _Category.image: _cmds({
      'eog': 'Image Viewer',
      'gwenview': 'Gwenview',
      'gthumb': 'gThumb',
      'feh': 'feh',
    }),
    _Category.video: _cmds({'vlc': 'VLC', 'mpv': 'mpv', 'totem': 'Videos'}),
    _Category.audio: _cmds({
      'vlc': 'VLC',
      'mpv': 'mpv',
      'rhythmbox': 'Rhythmbox',
    }),
    _Category.pdf: _cmds({
      'evince': 'Document Viewer',
      'okular': 'Okular',
      'xpdf': 'xpdf',
    }),
    _Category.editor: _cmds({
      'gnome-text-editor': 'Text Editor',
      'gedit': 'gedit',
      'kate': 'Kate',
      'mousepad': 'Mousepad',
    }),
  };

  static final _windows = <_Category, List<_Candidate>>{
    _Category.image: [
      _winExe('mspaint.exe', 'Paint', system32: true),
      _winExe(r'IrfanView\i_view64.exe', 'IrfanView', programFiles: true),
    ],
    _Category.video: [
      _winExe(r'VideoLAN\VLC\vlc.exe', 'VLC', programFiles: true),
    ],
    _Category.audio: [
      _winExe(r'VideoLAN\VLC\vlc.exe', 'VLC', programFiles: true),
    ],
    _Category.editor: [
      _winExe('notepad.exe', 'Notepad', system32: true),
    ],
    _Category.pdf: [],
  };

  static final _macos = <_Category, List<_Candidate>>{
    _Category.image: [_macApp('/System/Applications/Preview.app', 'Preview')],
    _Category.video: [
      _macApp('/Applications/VLC.app', 'VLC'),
      _macApp('/System/Applications/QuickTime Player.app', 'QuickTime Player'),
    ],
    _Category.audio: [
      _macApp('/Applications/VLC.app', 'VLC'),
      _macApp('/System/Applications/Music.app', 'Music'),
    ],
    _Category.pdf: [_macApp('/System/Applications/Preview.app', 'Preview')],
    _Category.editor: [
      _macApp('/System/Applications/TextEdit.app', 'TextEdit'),
    ],
  };

  static List<_Candidate> _cmds(Map<String, String> nameByCmd) =>
      nameByCmd.entries
          .map((e) => _Candidate.linuxCmd(e.key, e.value))
          .toList();

  static _Candidate _winExe(
    String rel,
    String name, {
    bool system32 = false,
    bool programFiles = false,
  }) => _Candidate.windowsExe(rel, name,
      system32: system32, programFiles: programFiles);

  static _Candidate _macApp(String path, String name) =>
      _Candidate.macApp(path, name);
}

enum _Category { image, video, audio, pdf, editor }

class _Candidate {
  final String id;
  final String name;
  final String? Function() resolve;

  _Candidate._(this.id, this.name, this.resolve);

  factory _Candidate.linuxCmd(String cmd, String name) {
    return _Candidate._(cmd, name, () {
      final found = _whichOnPath(cmd);
      return found == null ? null : '$cmd %f';
    });
  }

  factory _Candidate.windowsExe(
    String rel,
    String name, {
    required bool system32,
    required bool programFiles,
  }) {
    return _Candidate._(rel, name, () {
      final roots = <String>[
        if (system32)
          p.join(Platform.environment['SystemRoot'] ?? r'C:\Windows',
              'System32'),
        if (programFiles) ...[
          Platform.environment['ProgramFiles'] ?? r'C:\Program Files',
          Platform.environment['ProgramFiles(x86)'] ??
              r'C:\Program Files (x86)',
        ],
      ];
      for (final root in roots) {
        final candidate = p.join(root, rel);
        if (File(candidate).existsSync()) return candidate;
      }
      return null;
    });
  }

  factory _Candidate.macApp(String appPath, String name) {
    return _Candidate._(
      appPath,
      name,
      () => Directory(appPath).existsSync() ? appPath : null,
    );
  }
}

String? _whichOnPath(String cmd) {
  final pathEnv = Platform.environment['PATH'];
  if (pathEnv == null) return null;
  for (final dir in pathEnv.split(':')) {
    if (dir.isEmpty) continue;
    final f = p.join(dir, cmd);
    if (File(f).existsSync()) return f;
  }
  return null;
}
