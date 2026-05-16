import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as p;

class LibarchiveLoadResult {
  final DynamicLibrary? library;
  final String? path;
  final Object? error;

  const LibarchiveLoadResult.available(this.library, this.path) : error = null;

  const LibarchiveLoadResult.unavailable(this.error)
    : library = null,
      path = null;

  bool get isAvailable => library != null;
}

typedef _ArchiveVersionStringNative = Pointer<Utf8> Function();
typedef _ArchiveVersionStringDart = Pointer<Utf8> Function();

class LibarchiveLoader {
  LibarchiveLoader._();

  static LibarchiveLoadResult? _cached;

  static LibarchiveLoadResult load() {
    final cached = _cached;
    if (cached != null) return cached;

    Object? lastError;
    for (final path in _candidatePaths()) {
      try {
        final library = DynamicLibrary.open(path);
        final result = LibarchiveLoadResult.available(library, path);
        _cached = result;
        return result;
      } catch (e) {
        lastError = e;
      }
    }

    final result = LibarchiveLoadResult.unavailable(lastError);
    _cached = result;
    return result;
  }

  static String? versionString() {
    final result = load();
    final library = result.library;
    if (library == null) return null;
    try {
      final fn = library
          .lookupFunction<
            _ArchiveVersionStringNative,
            _ArchiveVersionStringDart
          >('archive_version_string');
      return fn().toDartString();
    } catch (_) {
      return null;
    }
  }

  static void resetForTest() {
    _cached = null;
  }

  static List<String> _candidatePaths() {
    final exeDir = p.dirname(Platform.resolvedExecutable);
    if (Platform.isWindows) {
      return [
        p.join(exeDir, 'archive.dll'),
        p.join(exeDir, 'libarchive.dll'),
        'archive.dll',
        'libarchive.dll',
      ];
    }
    if (Platform.isMacOS) {
      return [
        p.normalize(p.join(exeDir, '..', 'Frameworks', 'libarchive.dylib')),
        p.join(exeDir, 'libarchive.dylib'),
        'libarchive.dylib',
        '/opt/homebrew/opt/libarchive/lib/libarchive.dylib',
        '/usr/local/opt/libarchive/lib/libarchive.dylib',
      ];
    }
    return [
      p.join(exeDir, 'lib', 'libarchive.so.13'),
      p.join(exeDir, 'lib', 'libarchive.so'),
      'libarchive.so.13',
      'libarchive.so',
    ];
  }
}
