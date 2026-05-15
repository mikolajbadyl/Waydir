import 'dart:io';
import 'dart:typed_data';

import 'platform_paths.dart';

const String kRecycleBinPath = '::recycle-bin';

class RecycleBinEntry {
  final String dataPath;
  final String infoPath;
  final String originalPath;
  final DateTime deletedAt;
  final int size;
  final bool isDirectory;

  const RecycleBinEntry({
    required this.dataPath,
    required this.infoPath,
    required this.originalPath,
    required this.deletedAt,
    required this.size,
    required this.isDirectory,
  });

  String get name {
    final i = originalPath.lastIndexOf(RegExp(r'[\\/]'));
    return i < 0 ? originalPath : originalPath.substring(i + 1);
  }
}

class _Info {
  final String originalPath;
  final DateTime deletedAt;
  final int size;
  const _Info({
    required this.originalPath,
    required this.deletedAt,
    required this.size,
  });
}

class RecycleBinService {
  static const int _filetimeUnixEpoch = 116444736000000000;

  static Future<List<RecycleBinEntry>> list() async {
    if (!Platform.isWindows) return const [];
    final sid = await _getUserSid();
    if (sid == null) return const [];

    final entries = <RecycleBinEntry>[];
    for (var i = 0; i < 26; i++) {
      final letter = String.fromCharCode(65 + i);
      final binDir = Directory('$letter:\\\$Recycle.Bin\\$sid');
      if (!binDir.existsSync()) continue;
      try {
        for (final ent in binDir.listSync(followLinks: false)) {
          final name = PlatformPaths.fileName(ent.path);
          if (!name.startsWith(r'$I')) continue;
          final dataName = '\$R${name.substring(2)}';
          final dataPath = '${binDir.path}\\$dataName';
          final isDir = Directory(dataPath).existsSync();
          final isFile = File(dataPath).existsSync();
          if (!isDir && !isFile) continue;
          try {
            final info = _parseInfo(ent.path);
            if (info == null) continue;
            entries.add(
              RecycleBinEntry(
                dataPath: dataPath,
                infoPath: ent.path,
                originalPath: info.originalPath,
                deletedAt: info.deletedAt,
                size: info.size,
                isDirectory: isDir,
              ),
            );
          } catch (_) {}
        }
      } catch (_) {}
    }
    entries.sort((a, b) => b.deletedAt.compareTo(a.deletedAt));
    return entries;
  }

  static Future<void> restore(RecycleBinEntry e) async {
    final parentDir = Directory(PlatformPaths.parentOf(e.originalPath));
    if (!parentDir.existsSync()) parentDir.createSync(recursive: true);
    if (e.isDirectory) {
      Directory(e.dataPath).renameSync(e.originalPath);
    } else {
      File(e.dataPath).renameSync(e.originalPath);
    }
    _deleteIfExists(e.infoPath);
  }

  static Future<void> deletePermanently(RecycleBinEntry e) async {
    if (e.isDirectory) {
      Directory(e.dataPath).deleteSync(recursive: true);
    } else if (File(e.dataPath).existsSync()) {
      File(e.dataPath).deleteSync();
    }
    _deleteIfExists(e.infoPath);
  }

  static void _deleteIfExists(String path) {
    final f = File(path);
    if (f.existsSync()) f.deleteSync();
  }

  static Future<String?> _getUserSid() async {
    try {
      final r = await Process.run('whoami', ['/user', '/fo', 'csv', '/nh']);
      if (r.exitCode != 0) return null;
      final match = RegExp(
        r'"(S-1-[0-9-]+)"',
      ).firstMatch(r.stdout.toString());
      return match?.group(1);
    } catch (_) {
      return null;
    }
  }

  static _Info? _parseInfo(String path) {
    final bytes = File(path).readAsBytesSync();
    if (bytes.length < 24) return null;
    final bd = ByteData.sublistView(bytes);
    final version = bd.getUint64(0, Endian.little);
    final size = bd.getUint64(8, Endian.little);
    final filetime = bd.getUint64(16, Endian.little);
    final unixMs = (filetime - _filetimeUnixEpoch) ~/ 10000;
    final deletedAt = DateTime.fromMillisecondsSinceEpoch(
      unixMs,
      isUtc: true,
    ).toLocal();

    String originalPath;
    if (version == 1) {
      const fixedBytes = 520;
      if (bytes.length < 24 + fixedBytes) return null;
      originalPath = _utf16(bytes, 24, fixedBytes);
    } else {
      if (bytes.length < 28) return null;
      final pathChars = bd.getUint32(24, Endian.little);
      final pathBytes = pathChars * 2;
      if (bytes.length < 28 + pathBytes) return null;
      originalPath = _utf16(bytes, 28, pathBytes);
    }
    return _Info(
      originalPath: originalPath,
      deletedAt: deletedAt,
      size: size,
    );
  }

  static String _utf16(Uint8List bytes, int offset, int length) {
    final bd = ByteData.sublistView(bytes, offset, offset + length);
    final sb = StringBuffer();
    for (var i = 0; i + 1 < length; i += 2) {
      final code = bd.getUint16(i, Endian.little);
      if (code == 0) break;
      sb.writeCharCode(code);
    }
    return sb.toString();
  }
}
