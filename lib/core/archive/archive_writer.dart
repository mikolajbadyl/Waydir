import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as p;

import 'archive_reader.dart'
    show ArchiveReadException, ArchiveUnavailableException, ArchiveReader;
import 'libarchive_loader.dart';

enum ArchiveFormat { zip, tar, tarGz, tarBz2, tarXz, sevenZip }

enum CompressionLevel { store, normal, maximum }

extension ArchiveFormatInfo on ArchiveFormat {
  String get extension => switch (this) {
    ArchiveFormat.zip => 'zip',
    ArchiveFormat.tar => 'tar',
    ArchiveFormat.tarGz => 'tar.gz',
    ArchiveFormat.tarBz2 => 'tar.bz2',
    ArchiveFormat.tarXz => 'tar.xz',
    ArchiveFormat.sevenZip => '7z',
  };

  String get label => switch (this) {
    ArchiveFormat.zip => 'ZIP',
    ArchiveFormat.tar => 'TAR',
    ArchiveFormat.tarGz => 'TAR.GZ',
    ArchiveFormat.tarBz2 => 'TAR.BZ2',
    ArchiveFormat.tarXz => 'TAR.XZ',
    ArchiveFormat.sevenZip => '7Z',
  };
}

ArchiveFormat? archiveFormatFromName(String name) {
  final lower = name.toLowerCase();
  if (lower.endsWith('.tar.gz') || lower.endsWith('.tgz')) {
    return ArchiveFormat.tarGz;
  }
  if (lower.endsWith('.tar.bz2') || lower.endsWith('.tbz2')) {
    return ArchiveFormat.tarBz2;
  }
  if (lower.endsWith('.tar.xz') || lower.endsWith('.txz')) {
    return ArchiveFormat.tarXz;
  }
  if (lower.endsWith('.tar')) return ArchiveFormat.tar;
  if (lower.endsWith('.7z')) return ArchiveFormat.sevenZip;
  if (lower.endsWith('.zip')) return ArchiveFormat.zip;
  return null;
}

const int _archiveOk = 0;
const int _aeIfreg = 0x8000;
const int _aeIfdir = 0x4000;

typedef _PtrFn = Pointer<Void> Function();
typedef _IntFn = Int32 Function(Pointer<Void>);
typedef _IntFnD = int Function(Pointer<Void>);
typedef _IntStrNative = Int32 Function(Pointer<Void>, Pointer<Utf8>);
typedef _IntStrDart = int Function(Pointer<Void>, Pointer<Utf8>);
typedef _OpenNative = Int32 Function(Pointer<Void>, Pointer<Utf8>);
typedef _OpenDart = int Function(Pointer<Void>, Pointer<Utf8>);
typedef _SetPathNative = Void Function(Pointer<Void>, Pointer<Utf8>);
typedef _SetPathDart = void Function(Pointer<Void>, Pointer<Utf8>);
typedef _SetI64Native = Void Function(Pointer<Void>, Int64);
typedef _SetI64Dart = void Function(Pointer<Void>, int);
typedef _SetU32Native = Void Function(Pointer<Void>, Uint32);
typedef _SetU32Dart = void Function(Pointer<Void>, int);
typedef _WriteHeaderNative = Int32 Function(Pointer<Void>, Pointer<Void>);
typedef _WriteHeaderDart = int Function(Pointer<Void>, Pointer<Void>);
typedef _WriteDataNative = IntPtr Function(Pointer<Void>, Pointer<Uint8>, Size);
typedef _WriteDataDart = int Function(Pointer<Void>, Pointer<Uint8>, int);
typedef _EntryFreeNative = Void Function(Pointer<Void>);
typedef _EntryFreeDart = void Function(Pointer<Void>);
typedef _ErrStrNative = Pointer<Utf8> Function(Pointer<Void>);

class _WLib {
  final Pointer<Void> Function() writeNew;
  final int Function(Pointer<Void>) setFormatZip;
  final int Function(Pointer<Void>) setFormatPax;
  final int Function(Pointer<Void>) setFormat7zip;
  final int Function(Pointer<Void>) addFilterGzip;
  final int Function(Pointer<Void>) addFilterBzip2;
  final int Function(Pointer<Void>) addFilterXz;
  final int Function(Pointer<Void>) addFilterNone;
  final int Function(Pointer<Void>, Pointer<Utf8>) setOptions;
  final int Function(Pointer<Void>, Pointer<Utf8>) openFilename;
  final Pointer<Void> Function() entryNew;
  final void Function(Pointer<Void>, Pointer<Utf8>) entrySetPathname;
  final void Function(Pointer<Void>, int) entrySetSize;
  final void Function(Pointer<Void>, int) entrySetFiletype;
  final void Function(Pointer<Void>, int) entrySetPerm;
  final int Function(Pointer<Void>, Pointer<Void>) writeHeader;
  final int Function(Pointer<Void>, Pointer<Uint8>, int) writeData;
  final void Function(Pointer<Void>) entryFree;
  final int Function(Pointer<Void>) writeClose;
  final int Function(Pointer<Void>) writeFree;
  final Pointer<Utf8> Function(Pointer<Void>) errorString;

  _WLib(DynamicLibrary l)
    : writeNew = l.lookupFunction<_PtrFn, _PtrFn>('archive_write_new'),
      setFormatZip = l.lookupFunction<_IntFn, _IntFnD>(
        'archive_write_set_format_zip',
      ),
      setFormatPax = l.lookupFunction<_IntFn, _IntFnD>(
        'archive_write_set_format_pax_restricted',
      ),
      setFormat7zip = l.lookupFunction<_IntFn, _IntFnD>(
        'archive_write_set_format_7zip',
      ),
      addFilterGzip = l.lookupFunction<_IntFn, _IntFnD>(
        'archive_write_add_filter_gzip',
      ),
      addFilterBzip2 = l.lookupFunction<_IntFn, _IntFnD>(
        'archive_write_add_filter_bzip2',
      ),
      addFilterXz = l.lookupFunction<_IntFn, _IntFnD>(
        'archive_write_add_filter_xz',
      ),
      addFilterNone = l.lookupFunction<_IntFn, _IntFnD>(
        'archive_write_add_filter_none',
      ),
      setOptions = l.lookupFunction<_IntStrNative, _IntStrDart>(
        'archive_write_set_options',
      ),
      openFilename = l.lookupFunction<_OpenNative, _OpenDart>(
        'archive_write_open_filename',
      ),
      entryNew = l.lookupFunction<_PtrFn, _PtrFn>('archive_entry_new'),
      entrySetPathname = l.lookupFunction<_SetPathNative, _SetPathDart>(
        'archive_entry_set_pathname',
      ),
      entrySetSize = l.lookupFunction<_SetI64Native, _SetI64Dart>(
        'archive_entry_set_size',
      ),
      entrySetFiletype = l.lookupFunction<_SetU32Native, _SetU32Dart>(
        'archive_entry_set_filetype',
      ),
      entrySetPerm = l.lookupFunction<_SetU32Native, _SetU32Dart>(
        'archive_entry_set_perm',
      ),
      writeHeader = l.lookupFunction<_WriteHeaderNative, _WriteHeaderDart>(
        'archive_write_header',
      ),
      writeData = l.lookupFunction<_WriteDataNative, _WriteDataDart>(
        'archive_write_data',
      ),
      entryFree = l.lookupFunction<_EntryFreeNative, _EntryFreeDart>(
        'archive_entry_free',
      ),
      writeClose = l.lookupFunction<_IntFn, _IntFnD>('archive_write_close'),
      writeFree = l.lookupFunction<_IntFn, _IntFnD>('archive_write_free'),
      errorString = l.lookupFunction<_ErrStrNative, _ErrStrNative>(
        'archive_error_string',
      );
}

class _PlannedEntry {
  final String absPath;
  final String archiveName;
  final bool isDir;
  final int size;
  const _PlannedEntry(this.absPath, this.archiveName, this.isDir, this.size);
}

class ArchiveWriter {
  ArchiveWriter._();

  static _WLib _lib() {
    final result = LibarchiveLoader.load();
    final library = result.library;
    if (library == null) throw const ArchiveUnavailableException();
    return _WLib(library);
  }

  static int _levelValue(CompressionLevel level) => switch (level) {
    CompressionLevel.store => 0,
    CompressionLevel.normal => 6,
    CompressionLevel.maximum => 9,
  };

  static List<_PlannedEntry> _plan(List<String> sources) {
    final out = <_PlannedEntry>[];
    for (final src in sources) {
      final base = p.dirname(src);
      final type = FileSystemEntity.typeSync(src);
      if (type == FileSystemEntityType.notFound) continue;
      if (type == FileSystemEntityType.directory) {
        out.add(_PlannedEntry(src, p.relative(src, from: base), true, 0));
        for (final e in Directory(
          src,
        ).listSync(recursive: true, followLinks: false)) {
          final isDir = e is Directory;
          int size = 0;
          if (!isDir) {
            try {
              size = File(e.path).lengthSync();
            } catch (_) {
              continue;
            }
          }
          out.add(
            _PlannedEntry(e.path, p.relative(e.path, from: base), isDir, size),
          );
        }
      } else {
        int size = 0;
        try {
          size = File(src).lengthSync();
        } catch (_) {
          continue;
        }
        out.add(_PlannedEntry(src, p.relative(src, from: base), false, size));
      }
    }
    return out;
  }

  static String _options(ArchiveFormat format, CompressionLevel level) {
    final n = _levelValue(level);
    return switch (format) {
      ArchiveFormat.zip =>
        level == CompressionLevel.store
            ? 'zip:compression=store'
            : 'zip:compression-level=$n',
      ArchiveFormat.tar => '',
      ArchiveFormat.tarGz => 'gzip:compression-level=$n',
      ArchiveFormat.tarBz2 => 'bzip2:compression-level=$n',
      ArchiveFormat.tarXz => 'xz:compression-level=$n',
      ArchiveFormat.sevenZip =>
        level == CompressionLevel.store
            ? '7zip:compression=copy'
            : '7zip:compression=lzma2,7zip:compression-level=$n',
    };
  }

  static String _err(_WLib lib, Pointer<Void> a) {
    try {
      final ptr = lib.errorString(a);
      if (ptr == nullptr) return 'archive error';
      return ptr.toDartString();
    } catch (_) {
      return 'archive error';
    }
  }

  static int planCount(List<String> sources) => _plan(sources).length;

  static void create(
    List<String> sources,
    String destPath,
    ArchiveFormat format,
    CompressionLevel level, {
    void Function(String name)? onEntry,
    bool Function()? isCancelled,
  }) {
    final lib = _lib();
    final a = lib.writeNew();
    if (a == nullptr) {
      throw const ArchiveReadException('archive_write_new failed');
    }
    final destPtr = destPath.toNativeUtf8();
    const bufSize = 256 * 1024;
    final buf = calloc<Uint8>(bufSize);
    try {
      switch (format) {
        case ArchiveFormat.zip:
          lib.setFormatZip(a);
          lib.addFilterNone(a);
        case ArchiveFormat.tar:
          lib.setFormatPax(a);
          lib.addFilterNone(a);
        case ArchiveFormat.tarGz:
          lib.setFormatPax(a);
          lib.addFilterGzip(a);
        case ArchiveFormat.tarBz2:
          lib.setFormatPax(a);
          lib.addFilterBzip2(a);
        case ArchiveFormat.tarXz:
          lib.setFormatPax(a);
          lib.addFilterXz(a);
        case ArchiveFormat.sevenZip:
          lib.setFormat7zip(a);
      }
      final opts = _options(format, level);
      if (opts.isNotEmpty) {
        final optPtr = opts.toNativeUtf8();
        try {
          lib.setOptions(a, optPtr);
        } finally {
          calloc.free(optPtr);
        }
      }
      if (lib.openFilename(a, destPtr) != _archiveOk) {
        throw ArchiveReadException(_err(lib, a));
      }

      for (final entry in _plan(sources)) {
        if (isCancelled != null && isCancelled()) break;
        final h = lib.entryNew();
        final namePtr =
            (entry.isDir ? '${entry.archiveName}/' : entry.archiveName)
                .toNativeUtf8();
        try {
          lib.entrySetPathname(h, namePtr);
          lib.entrySetFiletype(h, entry.isDir ? _aeIfdir : _aeIfreg);
          lib.entrySetPerm(h, entry.isDir ? 0x1ED : 0x1A4);
          lib.entrySetSize(h, entry.isDir ? 0 : entry.size);
          if (lib.writeHeader(a, h) != _archiveOk) {
            throw ArchiveReadException(_err(lib, a));
          }
          if (!entry.isDir) {
            final raf = File(entry.absPath).openSync();
            try {
              while (true) {
                final n = raf.readIntoSync(buf.asTypedList(bufSize));
                if (n <= 0) break;
                if (lib.writeData(a, buf, n) < 0) {
                  throw ArchiveReadException(_err(lib, a));
                }
              }
            } finally {
              raf.closeSync();
            }
          }
          onEntry?.call(entry.archiveName);
        } finally {
          lib.entryFree(h);
          calloc.free(namePtr);
        }
      }
    } finally {
      lib.writeClose(a);
      lib.writeFree(a);
      calloc.free(destPtr);
      calloc.free(buf);
    }
  }

  static void _copyInto(String src, String destDir) {
    final type = FileSystemEntity.typeSync(src);
    final target = p.join(destDir, p.basename(src));
    if (type == FileSystemEntityType.directory) {
      Directory(target).createSync(recursive: true);
      for (final e in Directory(src).listSync(followLinks: false)) {
        _copyInto(e.path, target);
      }
    } else if (type == FileSystemEntityType.file) {
      Directory(destDir).createSync(recursive: true);
      File(src).copySync(target);
    }
  }

  static int editPlanCount(String archivePath, List<String> addSources) {
    var count = 0;
    try {
      count += ArchiveReader.listEntries(archivePath).length;
    } catch (_) {}
    count += planCount(addSources);
    return count;
  }

  static void mutate(
    String archivePath, {
    List<String> addSources = const [],
    String addInner = '',
    List<String> deleteInner = const [],
    String? renameFromInner,
    String? renameToName,
    void Function(String name)? onEntry,
    bool Function()? isCancelled,
  }) {
    final format = archiveFormatFromName(archivePath);
    if (format == null) {
      throw const ArchiveReadException('unsupported archive format');
    }
    final work = Directory(
      p.join(
        Directory.systemTemp.path,
        'waydir-archive-edit',
        DateTime.now().microsecondsSinceEpoch.toString(),
      ),
    )..createSync(recursive: true);
    final tree = Directory(p.join(work.path, 'tree'))
      ..createSync(recursive: true);
    final tmpArchive = p.join(work.path, p.basename(archivePath));
    try {
      ArchiveReader.extractAll(archivePath, tree.path);

      for (final rel in deleteInner) {
        final target = p.join(tree.path, rel);
        final type = FileSystemEntity.typeSync(target);
        if (type == FileSystemEntityType.directory) {
          Directory(target).deleteSync(recursive: true);
        } else if (type != FileSystemEntityType.notFound) {
          File(target).deleteSync();
        }
      }

      if (renameFromInner != null && renameToName != null) {
        final from = p.join(tree.path, renameFromInner);
        final to = p.join(p.dirname(from), renameToName);
        final type = FileSystemEntity.typeSync(from);
        if (type == FileSystemEntityType.directory) {
          Directory(from).renameSync(to);
        } else if (type != FileSystemEntityType.notFound) {
          File(from).renameSync(to);
        }
      }

      final innerDir = addInner.isEmpty
          ? tree.path
          : p.join(tree.path, addInner);
      if (addSources.isNotEmpty) {
        Directory(innerDir).createSync(recursive: true);
        for (final s in addSources) {
          if (isCancelled != null && isCancelled()) break;
          _copyInto(s, innerDir);
        }
      }

      final roots = tree
          .listSync(followLinks: false)
          .map((e) => e.path)
          .toList();
      create(
        roots,
        tmpArchive,
        format,
        CompressionLevel.normal,
        onEntry: onEntry,
        isCancelled: isCancelled,
      );
      if (isCancelled != null && isCancelled()) return;
      File(tmpArchive).copySync(archivePath);
    } finally {
      try {
        work.deleteSync(recursive: true);
      } catch (_) {}
    }
  }
}
