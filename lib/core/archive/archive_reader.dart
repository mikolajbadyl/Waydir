import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

import 'libarchive_loader.dart';

class ArchiveUnavailableException implements Exception {
  const ArchiveUnavailableException();
  @override
  String toString() => 'libarchive is not available';
}

class ArchiveReadException implements Exception {
  final String message;
  const ArchiveReadException(this.message);
  @override
  String toString() => message;
}

class ArchiveEntry {
  final String path;
  final int size;
  final bool isDir;
  final int mtimeSeconds;

  const ArchiveEntry({
    required this.path,
    required this.size,
    required this.isDir,
    required this.mtimeSeconds,
  });
}

const int _archiveOk = 0;
const int _archiveEof = 1;
const int _archiveFatal = -30;
const int _aeIfmt = 0xF000;
const int _aeIfdir = 0x4000;

typedef _PtrFn = Pointer<Void> Function();
typedef _IntPtrFn = Int32 Function(Pointer<Void>);
typedef _IntPtrFnD = int Function(Pointer<Void>);

typedef _OpenFileNative = Int32 Function(Pointer<Void>, Pointer<Utf8>, Size);
typedef _OpenFileDart = int Function(Pointer<Void>, Pointer<Utf8>, int);

typedef _NextHeaderNative =
    Int32 Function(Pointer<Void>, Pointer<Pointer<Void>>);
typedef _NextHeaderDart = int Function(Pointer<Void>, Pointer<Pointer<Void>>);

typedef _EntryPathNative = Pointer<Utf8> Function(Pointer<Void>);
typedef _EntrySizeNative = Int64 Function(Pointer<Void>);
typedef _EntrySizeDart = int Function(Pointer<Void>);
typedef _EntryModeNative = Uint32 Function(Pointer<Void>);
typedef _EntryModeDart = int Function(Pointer<Void>);
typedef _EntryMtimeNative = Int64 Function(Pointer<Void>);
typedef _EntryMtimeDart = int Function(Pointer<Void>);

typedef _ReadDataNative = IntPtr Function(Pointer<Void>, Pointer<Uint8>, Size);
typedef _ReadDataDart = int Function(Pointer<Void>, Pointer<Uint8>, int);

typedef _ErrorStringNative = Pointer<Utf8> Function(Pointer<Void>);

class _Lib {
  final Pointer<Void> Function() readNew;
  final int Function(Pointer<Void>) supportFilterAll;
  final int Function(Pointer<Void>) supportFormatAll;
  final int Function(Pointer<Void>, Pointer<Utf8>, int) openFilename;
  final int Function(Pointer<Void>, Pointer<Pointer<Void>>) nextHeader;
  final Pointer<Utf8> Function(Pointer<Void>) entryPathname;
  final int Function(Pointer<Void>) entrySize;
  final int Function(Pointer<Void>) entryFiletype;
  final int Function(Pointer<Void>) entryMtime;
  final int Function(Pointer<Void>) dataSkip;
  final int Function(Pointer<Void>, Pointer<Uint8>, int) readData;
  final int Function(Pointer<Void>) readClose;
  final int Function(Pointer<Void>) readFree;
  final Pointer<Utf8> Function(Pointer<Void>) errorString;

  _Lib(DynamicLibrary l)
    : readNew = l.lookupFunction<_PtrFn, _PtrFn>('archive_read_new'),
      supportFilterAll = l.lookupFunction<_IntPtrFn, _IntPtrFnD>(
        'archive_read_support_filter_all',
      ),
      supportFormatAll = l.lookupFunction<_IntPtrFn, _IntPtrFnD>(
        'archive_read_support_format_all',
      ),
      openFilename = l.lookupFunction<_OpenFileNative, _OpenFileDart>(
        'archive_read_open_filename',
      ),
      nextHeader = l.lookupFunction<_NextHeaderNative, _NextHeaderDart>(
        'archive_read_next_header',
      ),
      entryPathname = l.lookupFunction<_EntryPathNative, _EntryPathNative>(
        'archive_entry_pathname',
      ),
      entrySize = l.lookupFunction<_EntrySizeNative, _EntrySizeDart>(
        'archive_entry_size',
      ),
      entryFiletype = l.lookupFunction<_EntryModeNative, _EntryModeDart>(
        'archive_entry_filetype',
      ),
      entryMtime = l.lookupFunction<_EntryMtimeNative, _EntryMtimeDart>(
        'archive_entry_mtime',
      ),
      dataSkip = l.lookupFunction<_IntPtrFn, _IntPtrFnD>(
        'archive_read_data_skip',
      ),
      readData = l.lookupFunction<_ReadDataNative, _ReadDataDart>(
        'archive_read_data',
      ),
      readClose = l.lookupFunction<_IntPtrFn, _IntPtrFnD>('archive_read_close'),
      readFree = l.lookupFunction<_IntPtrFn, _IntPtrFnD>('archive_read_free'),
      errorString = l.lookupFunction<_ErrorStringNative, _ErrorStringNative>(
        'archive_error_string',
      );
}

class ArchiveReader {
  ArchiveReader._();

  static _Lib _lib() {
    final result = LibarchiveLoader.load();
    final library = result.library;
    if (library == null) throw const ArchiveUnavailableException();
    return _Lib(library);
  }

  static String _err(_Lib lib, Pointer<Void> a) {
    try {
      final ptr = lib.errorString(a);
      if (ptr == nullptr) return 'archive error';
      return ptr.toDartString();
    } catch (_) {
      return 'archive error';
    }
  }

  static String _normalize(String path) {
    var p = path.replaceAll('\\', '/');
    while (p.endsWith('/')) {
      p = p.substring(0, p.length - 1);
    }
    while (p.startsWith('./')) {
      p = p.substring(2);
    }
    return p;
  }

  static List<ArchiveEntry> listEntries(String archivePath) {
    final lib = _lib();
    final a = lib.readNew();
    if (a == nullptr) {
      throw const ArchiveReadException('archive_read_new failed');
    }
    final namePtr = archivePath.toNativeUtf8();
    final headerPtr = calloc<Pointer<Void>>();
    final entries = <ArchiveEntry>[];
    try {
      lib.supportFilterAll(a);
      lib.supportFormatAll(a);
      if (lib.openFilename(a, namePtr, 16384) != _archiveOk) {
        throw ArchiveReadException(_err(lib, a));
      }
      while (true) {
        final r = lib.nextHeader(a, headerPtr);
        if (r == _archiveEof) break;
        if (r == _archiveFatal) throw ArchiveReadException(_err(lib, a));
        final entry = headerPtr.value;
        final pathPtr = lib.entryPathname(entry);
        if (pathPtr == nullptr) {
          lib.dataSkip(a);
          continue;
        }
        final raw = pathPtr.toDartString();
        final isDir =
            raw.endsWith('/') ||
            (lib.entryFiletype(entry) & _aeIfmt) == _aeIfdir;
        final name = _normalize(raw);
        if (name.isNotEmpty) {
          entries.add(
            ArchiveEntry(
              path: name,
              size: lib.entrySize(entry),
              isDir: isDir,
              mtimeSeconds: lib.entryMtime(entry),
            ),
          );
        }
        lib.dataSkip(a);
      }
    } finally {
      lib.readClose(a);
      lib.readFree(a);
      calloc.free(headerPtr);
      calloc.free(namePtr);
    }
    return entries;
  }

  static void extractEntry(
    String archivePath,
    String innerPath,
    String destPath,
  ) {
    final lib = _lib();
    final a = lib.readNew();
    if (a == nullptr) {
      throw const ArchiveReadException('archive_read_new failed');
    }
    final namePtr = archivePath.toNativeUtf8();
    final headerPtr = calloc<Pointer<Void>>();
    const bufSize = 256 * 1024;
    final buf = calloc<Uint8>(bufSize);
    RandomAccessFile? out;
    try {
      lib.supportFilterAll(a);
      lib.supportFormatAll(a);
      if (lib.openFilename(a, namePtr, 16384) != _archiveOk) {
        throw ArchiveReadException(_err(lib, a));
      }
      final target = _normalize(innerPath);
      var found = false;
      while (true) {
        final r = lib.nextHeader(a, headerPtr);
        if (r == _archiveEof) break;
        if (r == _archiveFatal) throw ArchiveReadException(_err(lib, a));
        final pathPtr = lib.entryPathname(headerPtr.value);
        if (pathPtr == nullptr) {
          lib.dataSkip(a);
          continue;
        }
        if (_normalize(pathPtr.toDartString()) != target) {
          lib.dataSkip(a);
          continue;
        }
        found = true;
        final file = File(destPath);
        file.parent.createSync(recursive: true);
        out = file.openSync(mode: FileMode.write);
        while (true) {
          final n = lib.readData(a, buf, bufSize);
          if (n == 0) break;
          if (n < 0) throw ArchiveReadException(_err(lib, a));
          out.writeFromSync(buf.asTypedList(n));
        }
        break;
      }
      if (!found) {
        throw ArchiveReadException('entry not found: $innerPath');
      }
    } finally {
      out?.closeSync();
      lib.readClose(a);
      lib.readFree(a);
      calloc.free(headerPtr);
      calloc.free(namePtr);
      calloc.free(buf);
    }
  }

  static String extractTree(
    String archivePath,
    String innerPath,
    String stagingDir,
  ) {
    final lib = _lib();
    final a = lib.readNew();
    if (a == nullptr) {
      throw const ArchiveReadException('archive_read_new failed');
    }
    final namePtr = archivePath.toNativeUtf8();
    final headerPtr = calloc<Pointer<Void>>();
    const bufSize = 256 * 1024;
    final buf = calloc<Uint8>(bufSize);
    final target = _normalize(innerPath);
    final baseName = target.contains('/')
        ? target.substring(target.lastIndexOf('/') + 1)
        : target;
    final stagedRoot = '$stagingDir/$baseName';
    var found = false;
    try {
      lib.supportFilterAll(a);
      lib.supportFormatAll(a);
      if (lib.openFilename(a, namePtr, 16384) != _archiveOk) {
        throw ArchiveReadException(_err(lib, a));
      }
      while (true) {
        final r = lib.nextHeader(a, headerPtr);
        if (r == _archiveEof) break;
        if (r == _archiveFatal) throw ArchiveReadException(_err(lib, a));
        final entry = headerPtr.value;
        final pathPtr = lib.entryPathname(entry);
        if (pathPtr == nullptr) {
          lib.dataSkip(a);
          continue;
        }
        final raw = pathPtr.toDartString();
        final epath = _normalize(raw);
        String dest;
        if (epath == target) {
          dest = stagedRoot;
        } else if (epath.startsWith('$target/')) {
          dest = '$stagedRoot/${epath.substring(target.length + 1)}';
        } else {
          lib.dataSkip(a);
          continue;
        }
        found = true;
        final isDir =
            raw.endsWith('/') ||
            (lib.entryFiletype(entry) & _aeIfmt) == _aeIfdir;
        if (isDir) {
          Directory(dest).createSync(recursive: true);
          lib.dataSkip(a);
          continue;
        }
        final file = File(dest);
        file.parent.createSync(recursive: true);
        final out = file.openSync(mode: FileMode.write);
        try {
          while (true) {
            final n = lib.readData(a, buf, bufSize);
            if (n == 0) break;
            if (n < 0) throw ArchiveReadException(_err(lib, a));
            out.writeFromSync(buf.asTypedList(n));
          }
        } finally {
          out.closeSync();
        }
      }
      if (!found) {
        throw ArchiveReadException('entry not found: $innerPath');
      }
    } finally {
      lib.readClose(a);
      lib.readFree(a);
      calloc.free(headerPtr);
      calloc.free(namePtr);
      calloc.free(buf);
    }
    return stagedRoot;
  }

  static bool _isUnsafe(String path) {
    if (path.startsWith('/')) return true;
    for (final seg in path.split('/')) {
      if (seg == '..') return true;
    }
    return false;
  }

  static void extractAll(
    String archivePath,
    String destDir, {
    void Function(String name)? onEntry,
    bool Function()? isCancelled,
  }) {
    final lib = _lib();
    final a = lib.readNew();
    if (a == nullptr) {
      throw const ArchiveReadException('archive_read_new failed');
    }
    final namePtr = archivePath.toNativeUtf8();
    final headerPtr = calloc<Pointer<Void>>();
    const bufSize = 256 * 1024;
    final buf = calloc<Uint8>(bufSize);
    try {
      lib.supportFilterAll(a);
      lib.supportFormatAll(a);
      if (lib.openFilename(a, namePtr, 16384) != _archiveOk) {
        throw ArchiveReadException(_err(lib, a));
      }
      Directory(destDir).createSync(recursive: true);
      while (true) {
        if (isCancelled != null && isCancelled()) break;
        final r = lib.nextHeader(a, headerPtr);
        if (r == _archiveEof) break;
        if (r == _archiveFatal) throw ArchiveReadException(_err(lib, a));
        final entry = headerPtr.value;
        final pathPtr = lib.entryPathname(entry);
        if (pathPtr == nullptr) {
          lib.dataSkip(a);
          continue;
        }
        final raw = pathPtr.toDartString();
        final epath = _normalize(raw);
        if (epath.isEmpty || _isUnsafe(epath)) {
          lib.dataSkip(a);
          continue;
        }
        final dest = '$destDir/$epath';
        onEntry?.call(epath);
        final isDir =
            raw.endsWith('/') ||
            (lib.entryFiletype(entry) & _aeIfmt) == _aeIfdir;
        if (isDir) {
          Directory(dest).createSync(recursive: true);
          lib.dataSkip(a);
          continue;
        }
        final file = File(dest);
        file.parent.createSync(recursive: true);
        final out = file.openSync(mode: FileMode.write);
        try {
          while (true) {
            final n = lib.readData(a, buf, bufSize);
            if (n == 0) break;
            if (n < 0) throw ArchiveReadException(_err(lib, a));
            out.writeFromSync(buf.asTypedList(n));
          }
        } finally {
          out.closeSync();
        }
      }
    } finally {
      lib.readClose(a);
      lib.readFree(a);
      calloc.free(headerPtr);
      calloc.free(namePtr);
      calloc.free(buf);
    }
  }
}
