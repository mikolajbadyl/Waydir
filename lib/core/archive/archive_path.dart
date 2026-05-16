import 'dart:io';

import 'package:path/path.dart' as p;

/// Resolved position inside an archive: the real archive file on disk and the
/// path of the entry within it (empty string == archive root).
class ArchiveLocation {
  final String archivePath;
  final String innerPath;

  const ArchiveLocation(this.archivePath, this.innerPath);

  bool get isRoot => innerPath.isEmpty;
}

/// Archives are browsed as if they were ordinary folders. A path such as
/// `/home/u/foo.zip/dir/file.txt` is split into the archive file
/// (`/home/u/foo.zip`) and the inner entry (`dir/file.txt`) by walking the
/// path and finding the first segment that is an existing file with a
/// supported archive extension.
class ArchivePath {
  ArchivePath._();

  /// Multi-part extensions checked before single extensions.
  static const _compoundExtensions = <String>[
    '.tar.gz',
    '.tar.bz2',
    '.tar.xz',
    '.tar.zst',
    '.tar.lz',
    '.tar.lzma',
    '.tar.z',
  ];

  static const _extensions = <String>{
    '.zip',
    '.tar',
    '.tgz',
    '.tbz',
    '.tbz2',
    '.txz',
    '.tzst',
    '.gz',
    '.bz2',
    '.xz',
    '.zst',
    '.7z',
    '.rar',
    '.iso',
    '.cab',
    '.lz',
    '.lzma',
    '.cpio',
    '.ar',
    '.a',
    '.deb',
    '.rpm',
    '.jar',
    '.war',
    '.apk',
    '.xpi',
    '.whl',
    '.crx',
    '.epub',
  };

  static bool isArchiveName(String name) {
    final lower = name.toLowerCase();
    for (final ext in _compoundExtensions) {
      if (lower.endsWith(ext)) return true;
    }
    return _extensions.contains(p.extension(lower));
  }

  /// Returns the archive location for [path], or `null` when [path] is not
  /// inside (or equal to) an archive file. Performs a few sync stat calls.
  static ArchiveLocation? resolve(String path) {
    final segments = p.split(path);
    if (segments.isEmpty) return null;

    var prefix = segments.first;
    for (var i = 0; i < segments.length; i++) {
      prefix = i == 0 ? segments.first : p.join(prefix, segments[i]);
      if (!isArchiveName(segments[i])) continue;
      if (FileSystemEntity.typeSync(prefix) != FileSystemEntityType.file) {
        continue;
      }
      final innerSegments = segments.sublist(i + 1);
      return ArchiveLocation(
        prefix,
        innerSegments.isEmpty ? '' : p.joinAll(innerSegments),
      );
    }
    return null;
  }
}
