import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:waydir/core/models/file_operation.dart';
import 'package:waydir/features/operations/operation_store.dart';

void main() {
  group('OperationStore conflicts', () {
    late Directory tmpDir;
    late OperationStore store;

    setUp(() {
      tmpDir = Directory.systemTemp.createTempSync('waydir_ops_');
      store = OperationStore();
    });

    tearDown(() {
      store.dispose();
      if (tmpDir.existsSync()) {
        tmpDir.deleteSync(recursive: true);
      }
    });

    test('copy waits for conflict resolution', () async {
      final sourceRoot = Directory(p.join(tmpDir.path, 'source'));
      final sourceFolder = Directory(p.join(sourceRoot.path, 'folder'))
        ..createSync(recursive: true);
      final sourceExtra = Directory(p.join(sourceFolder.path, 'extra'))
        ..createSync();
      File(p.join(sourceFolder.path, 'file.txt')).writeAsStringSync('new');
      File(p.join(sourceExtra.path, 'extra.txt')).writeAsStringSync('extra');

      final destination = Directory(p.join(tmpDir.path, 'destination'))
        ..createSync();
      final existingFolder = Directory(p.join(destination.path, 'folder'))
        ..createSync();
      File(p.join(existingFolder.path, 'file.txt')).writeAsStringSync('old');

      store.enqueueCopy([sourceFolder.path], destination.path);

      final waiting = await _waitForTask(
        store,
        (task) => task.status == TaskStatus.waitingConflicts,
      );
      expect(waiting.conflicts, isNotEmpty);
      expect(
        Directory(p.join(existingFolder.path, 'extra')).existsSync(),
        isFalse,
      );

      store.resolveCurrentConflict(waiting.id, ConflictResolution.rename);

      final done = await _waitForTask(
        store,
        (task) => task.status == TaskStatus.completed,
      );

      expect(done.errors, isEmpty);
      expect(
        File(p.join(existingFolder.path, 'file.txt')).readAsStringSync(),
        'old',
      );
      expect(
        File(p.join(existingFolder.path, 'file (1).txt')).readAsStringSync(),
        'new',
      );
      expect(
        File(
          p.join(existingFolder.path, 'extra', 'extra.txt'),
        ).readAsStringSync(),
        'extra',
      );
    });

    test('move keeps both when target folder exists', () async {
      final sourceRoot = Directory(p.join(tmpDir.path, 'source'));
      final sourceFolder = Directory(p.join(sourceRoot.path, 'folder'))
        ..createSync(recursive: true);
      File(p.join(sourceFolder.path, 'file.txt')).writeAsStringSync('new');

      final destination = Directory(p.join(tmpDir.path, 'destination'))
        ..createSync();
      final existingFolder = Directory(p.join(destination.path, 'folder'))
        ..createSync();
      File(p.join(existingFolder.path, 'file.txt')).writeAsStringSync('old');

      store.enqueueMove([sourceFolder.path], destination.path);

      final waiting = await _waitForTask(
        store,
        (task) => task.status == TaskStatus.waitingConflicts,
      );
      expect(waiting.conflicts.single.sourcePath, sourceFolder.path);

      store.resolveCurrentConflict(waiting.id, ConflictResolution.rename);

      final done = await _waitForTask(
        store,
        (task) => task.status == TaskStatus.completed,
      );

      final renamedFolder = Directory(p.join(destination.path, 'folder (1)'));
      expect(done.errors, isEmpty);
      expect(sourceFolder.existsSync(), isFalse);
      expect(
        File(p.join(existingFolder.path, 'file.txt')).readAsStringSync(),
        'old',
      );
      expect(
        File(p.join(renamedFolder.path, 'file.txt')).readAsStringSync(),
        'new',
      );
    });
  });
}

Future<FileTask> _waitForTask(
  OperationStore store,
  bool Function(FileTask task) predicate,
) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (DateTime.now().isBefore(deadline)) {
    for (final task in store.tasks.value) {
      if (predicate(task)) return task;
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  fail('Timed out waiting for task state');
}
