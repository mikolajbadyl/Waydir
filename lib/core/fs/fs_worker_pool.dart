import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import '../models/file_entry.dart';

enum _Op { list, exists, isDir, mkdir, delete, stat }

class _Request {
  final int id;
  final _Op op;
  final List<dynamic> args;
  const _Request(this.id, this.op, this.args);
}

class _Response {
  final int id;
  final dynamic result;
  final Object? error;
  const _Response(this.id, this.result, this.error);
}

class FsWorkerPool {
  static final FsWorkerPool instance = FsWorkerPool._();
  FsWorkerPool._();

  SendPort? _commandPort;
  ReceivePort? _replyPort;
  Isolate? _isolate;
  final _pending = <int, Completer<dynamic>>{};
  int _nextId = 0;
  Future<void>? _initFuture;

  Future<void> ensureStarted() {
    return _initFuture ??= _start();
  }

  Future<void> _start() async {
    final ready = ReceivePort();
    _isolate = await Isolate.spawn<SendPort>(
      _entryPoint,
      ready.sendPort,
      errorsAreFatal: false,
    );

    final completer = Completer<SendPort>();
    late StreamSubscription sub;
    sub = ready.listen((msg) {
      if (msg is SendPort && !completer.isCompleted) {
        completer.complete(msg);
        sub.cancel();
        ready.close();
      }
    });

    _commandPort = await completer.future;

    _replyPort = ReceivePort();
    _commandPort!.send(_replyPort!.sendPort);
    _replyPort!.listen((msg) {
      if (msg is _Response) {
        final completer = _pending.remove(msg.id);
        if (completer == null) return;
        if (msg.error != null) {
          completer.completeError(msg.error!);
        } else {
          completer.complete(msg.result);
        }
      }
    });
  }

  Future<T> _run<T>(_Op op, List<dynamic> args) async {
    await ensureStarted();
    final id = _nextId++;
    final completer = Completer<dynamic>();
    _pending[id] = completer;
    _commandPort!.send(_Request(id, op, args));
    final result = await completer.future;
    return result as T;
  }

  Future<List<FileEntry>> listDirectory(String path) =>
      _run<List<FileEntry>>(_Op.list, [path]);

  Future<bool> directoryExists(String path) =>
      _run<bool>(_Op.exists, [path]);

  Future<bool> isDirectory(String path) =>
      _run<bool>(_Op.isDir, [path]);

  Future<void> createDirectory(String path) =>
      _run<void>(_Op.mkdir, [path]);

  Future<void> delete(String path, {bool recursive = false}) =>
      _run<void>(_Op.delete, [path, recursive]);

  Future<FileEntry?> stat(String path) =>
      _run<FileEntry?>(_Op.stat, [path]);

  void dispose() {
    _replyPort?.close();
    _isolate?.kill(priority: Isolate.immediate);
    for (final c in _pending.values) {
      if (!c.isCompleted) c.completeError(StateError('Pool disposed'));
    }
    _pending.clear();
    _commandPort = null;
    _replyPort = null;
    _isolate = null;
    _initFuture = null;
  }

  static void _entryPoint(SendPort initial) {
    final commandPort = ReceivePort();
    initial.send(commandPort.sendPort);

    SendPort? replyPort;
    commandPort.listen((msg) {
      if (msg is SendPort) {
        replyPort = msg;
        return;
      }
      if (msg is _Request && replyPort != null) {
        try {
          final result = _execute(msg.op, msg.args);
          replyPort!.send(_Response(msg.id, result, null));
        } catch (e) {
          replyPort!.send(_Response(msg.id, null, e));
        }
      }
    });
  }

  static dynamic _execute(_Op op, List<dynamic> args) {
    switch (op) {
      case _Op.list:
        return _listDirectory(args[0] as String);
      case _Op.exists:
        return Directory(args[0] as String).existsSync();
      case _Op.isDir:
        return FileSystemEntity.isDirectorySync(args[0] as String);
      case _Op.mkdir:
        Directory(args[0] as String).createSync(recursive: true);
        return null;
      case _Op.delete:
        final path = args[0] as String;
        final recursive = args[1] as bool;
        final type = FileSystemEntity.typeSync(path, followLinks: false);
        if (type == FileSystemEntityType.link) {
          Link(path).deleteSync();
        } else if (type == FileSystemEntityType.directory) {
          Directory(path).deleteSync(recursive: recursive);
        } else if (type == FileSystemEntityType.file) {
          File(path).deleteSync();
        }
        return null;
      case _Op.stat:
        final path = args[0] as String;
        final type = FileSystemEntity.typeSync(path, followLinks: false);
        if (type == FileSystemEntityType.notFound) return null;
        final entity = type == FileSystemEntityType.directory
            ? Directory(path) as FileSystemEntity
            : (type == FileSystemEntityType.link
                ? Link(path)
                : File(path));
        return FileEntry.fromFileSystemEntity(entity);
    }
  }

  static List<FileEntry> _listDirectory(String path) {
    final dir = Directory(path);
    if (!dir.existsSync()) {
      throw FileSystemException('Directory not found', path);
    }

    final entries = dir.listSync(followLinks: false).map((e) {
      FileStat stat;
      try {
        stat = e.statSync();
      } catch (_) {
        stat = FileStat.statSync(e.path);
      }
      final isDir = e is Directory ||
          (e is Link && stat.type == FileSystemEntityType.directory);
      return FileEntry(
        name: e.path.split(Platform.pathSeparator).last,
        path: e.path,
        type: isDir ? FileItemType.folder : FileItemType.file,
        size: stat.size,
        modified: stat.modified,
      );
    }).toList();

    entries.sort((a, b) {
      if (a.type != b.type) return a.type == FileItemType.folder ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return entries;
  }
}
