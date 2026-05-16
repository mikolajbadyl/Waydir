import 'dart:io';

import 'package:path/path.dart' as p;

import '../platform/win32_attributes.dart';
import 'app_entry.dart';

/// Built-in fallback: when the OS default handler cannot be resolved, pick a
/// well-known application that is typical for the file's category on the
/// current platform and actually installed. Keeps double-click working with a
/// concrete, named app instead of nothing.
class TypicalApps {
  TypicalApps._();

  static AppEntry? forPath(String path) {
    final ext = p.extension(path).toLowerCase();
    final cat = _categoryFor(ext);
    if (cat == null) return null;
    // On Windows the sensible "typical" handler for a known type is whatever
    // the OS itself uses (Photos for images, the system PDF viewer, etc.) —
    // not a hardcoded app like Paint. We surface it under its OS-reported
    // friendly name and launch it via the system shell.
    if (Platform.isWindows) {
      final friendly = assocQueryStringOnWindows(assocStrFriendlyAppName, ext);
      return AppEntry.systemDefault(
        (friendly != null && friendly.isNotEmpty)
            ? friendly
            : _genericName[cat]!,
      );
    }
    final candidates = Platform.isMacOS ? _macos[cat] : _linux[cat];
    if (candidates == null) return null;
    for (final c in candidates) {
      final exec = c.resolve();
      if (exec != null) {
        return AppEntry(id: c.id, name: c.name, exec: exec, isDefault: true);
      }
    }
    return null;
  }

  static const _genericName = {
    _Category.image: 'Photos',
    _Category.video: 'Media Player',
    _Category.audio: 'Media Player',
    _Category.pdf: 'PDF Viewer',
    _Category.editor: 'Text Editor',
  };

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
