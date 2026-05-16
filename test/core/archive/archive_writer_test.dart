import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:waydir/core/archive/archive_reader.dart';
import 'package:waydir/core/archive/archive_writer.dart';
import 'package:waydir/core/archive/libarchive_loader.dart';

void main() {
  final available = LibarchiveLoader.load().isAvailable;

  group('ArchiveWriter', () {
    late Directory tmp;
    late String filePath;
    late String dirPath;

    setUp(() {
      tmp = Directory.systemTemp.createTempSync('waydir_writer');
      filePath = p.join(tmp.path, 'note.txt');
      File(filePath).writeAsStringSync('hello');
      dirPath = p.join(tmp.path, 'folder');
      Directory(p.join(dirPath, 'sub')).createSync(recursive: true);
      File(p.join(dirPath, 'a.txt')).writeAsStringSync('aaa');
      File(p.join(dirPath, 'sub', 'b.txt')).writeAsStringSync('bbb');
    });

    tearDown(() => tmp.deleteSync(recursive: true));

    test('planCount counts files and directories', () {
      expect(ArchiveWriter.planCount([filePath]), 1);
      expect(ArchiveWriter.planCount([dirPath]), 4);
    });

    for (final format in [
      ArchiveFormat.zip,
      ArchiveFormat.tar,
      ArchiveFormat.tarGz,
      ArchiveFormat.tarXz,
      ArchiveFormat.sevenZip,
    ]) {
      test('round-trips ${format.label}', () {
        final dest = p.join(tmp.path, 'out.${format.extension}');
        ArchiveWriter.create(
          [filePath, dirPath],
          dest,
          format,
          CompressionLevel.normal,
        );
        expect(File(dest).existsSync(), isTrue);

        final entries = ArchiveReader.listEntries(dest);
        final paths = entries.map((e) => e.path).toSet();
        expect(paths.contains('note.txt'), isTrue);
        expect(paths.contains('folder/a.txt'), isTrue);
        expect(paths.contains('folder/sub/b.txt'), isTrue);

        final back = p.join(tmp.path, 'back_${format.name}.txt');
        ArchiveReader.extractEntry(dest, 'folder/sub/b.txt', back);
        expect(File(back).readAsStringSync(), 'bbb');
      });
    }
  }, skip: available ? false : 'libarchive unavailable');
}
