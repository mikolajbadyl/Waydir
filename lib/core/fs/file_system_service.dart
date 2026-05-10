import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:path/path.dart' as p;
import '../models/file_entry.dart';
import '../models/file_operation.dart';
import '../platform/platform_paths.dart';
import '../platform/win32_attributes.dart';
import '../settings/settings_store.dart';
import '../terminal/terminal.dart';
import '../../i18n/strings.g.dart';
import 'fs_worker_pool.dart';

sealed class RenameResult {
  const RenameResult();
}

class RenameSuccess extends RenameResult {
  final String newPath;
  const RenameSuccess(this.newPath);
}

class RenameInvalidName extends RenameResult {
  const RenameInvalidName();
}

class RenameAlreadyExists extends RenameResult {
  const RenameAlreadyExists();
}

class RenameNoChange extends RenameResult {
  const RenameNoChange();
}

class RenameError extends RenameResult {
  final String message;
  const RenameError(this.message);
}

class FileSystemService {
  static RenameResult rename(String oldPath, String newName) {
    if (!PlatformPaths.isValidFileName(newName)) {
      return const RenameInvalidName();
    }

    final newPath = p.join(p.dirname(oldPath), newName);

    if (oldPath == newPath) return const RenameNoChange();

    if (FileSystemEntity.typeSync(newPath) != FileSystemEntityType.notFound) {
      return const RenameAlreadyExists();
    }

    try {
      final type = FileSystemEntity.typeSync(oldPath, followLinks: false);
      if (type == FileSystemEntityType.link) {
        Link(oldPath).renameSync(newPath);
      } else if (type == FileSystemEntityType.directory) {
        Directory(oldPath).renameSync(newPath);
      } else {
        File(oldPath).renameSync(newPath);
      }
      return RenameSuccess(newPath);
    } on FileSystemException catch (e) {
      return RenameError(_friendlyError(e));
    }
  }

  static Future<List<FileEntry>> listDirectory(String path) =>
      FsWorkerPool.instance.listDirectory(path);

  static Future<bool> directoryExists(String path) =>
      FsWorkerPool.instance.directoryExists(path);

  static Future<bool> isDirectory(String path) =>
      FsWorkerPool.instance.isDirectory(path);

  static Future<void> createDirectory(String path) =>
      FsWorkerPool.instance.createDirectory(path);

  static Future<void> openInTerminal(String directory) =>
      TerminalService.openInDirectory(
        directory,
        preferredId: SettingsStore.instance.terminal.value,
        customCommand: SettingsStore.instance.terminalCustomCommand.value,
      );

  static Future<void> openWithDefaultApp(String path) async {
    if (PlatformPaths.isWindows) {
      shellOpenOnWindows(path);
    } else if (Platform.isLinux) {
      await Process.start('xdg-open', [path], mode: ProcessStartMode.detached);
    } else if (Platform.isMacOS) {
      await Process.start('open', [path], mode: ProcessStartMode.detached);
    }
  }

  static void copyWorker(List<dynamic> args) {
    final mainSendPort = args[0] as SendPort;
    final workerReceivePort = ReceivePort();
    mainSendPort.send(workerReceivePort.sendPort);

    bool cancelled = false;
    final allPaths = <String>[];
    final sourceRoots = <String>{};
    final visitedDirs = <String>{};
    int totalBytes = 0;
    int totalFiles = 0;
    final conflicts = <ConflictInfo>[];
    Map<String, ConflictResolution> resolutions = {};
    final runtimeResolutions = <String, ConflictResolution>{};
    final pendingConflicts = <String, ConflictInfo>{};
    final promptedSet = <String>{};
    ConflictResolution? runtimeApplyAll;
    Completer<void>? decisionWaker;
    final errors = <TaskError>[];
    String? destination;
    int processedBytes = 0;
    int processedFiles = 0;
    var lastReport = DateTime.now();

    void emitPrompt(ConflictInfo info) {
      if (promptedSet.add(info.sourcePath)) {
        mainSendPort.send(ConflictPromptMessage(conflict: info));
      }
    }

    void wakeDecisions() {
      final w = decisionWaker;
      decisionWaker = null;
      w?.complete();
    }

    void maybeReport(String currentFile) {
      final now = DateTime.now();
      if (now.difference(lastReport).inMilliseconds > 50 ||
          processedFiles % 100 == 0) {
        mainSendPort.send(
          ProgressMessage(
            processedFiles: processedFiles,
            processedBytes: processedBytes,
            currentFile: currentFile,
          ),
        );
        lastReport = now;
      }
    }

    void scanEntity(String src, String dest) {
      final name = src.split(Platform.pathSeparator).last;
      final targetPath = '$dest${Platform.pathSeparator}$name';

      final type = FileSystemEntity.typeSync(src);
      if (type == FileSystemEntityType.notFound) {
        errors.add(TaskError(path: src, message: t.errors.notFound));
        mainSendPort.send(ErrorMessage(path: src, message: t.errors.notFound));
        return;
      }
      if (type == FileSystemEntityType.directory) {
        allPaths.add(src);
        totalFiles++;
        _scanDirForCopy(
          Directory(src),
          targetPath,
          visitedDirs,
          (path, bytes, conflict) {
            allPaths.add(path);
            totalFiles++;
            totalBytes += bytes;
            if (conflict != null) conflicts.add(conflict);
          },
          (errorPath, errorMsg) {
            errors.add(TaskError(path: errorPath, message: errorMsg));
            mainSendPort.send(ErrorMessage(path: errorPath, message: errorMsg));
          },
        );
      } else {
        try {
          final size = File(src).lengthSync();
          allPaths.add(src);
          totalFiles++;
          totalBytes += size;
          if (FileSystemEntity.typeSync(targetPath) !=
              FileSystemEntityType.notFound) {
            final targetStat = FileStat.statSync(targetPath);
            final sourceStat = FileStat.statSync(src);
            conflicts.add(
              ConflictInfo(
                sourcePath: src,
                targetPath: targetPath,
                name: name,
                sourceSize: size,
                targetSize: targetStat.size,
                sourceModified: sourceStat.modified,
                targetModified: targetStat.modified,
              ),
            );
          }
        } catch (e) {
          errors.add(TaskError(path: src, message: _friendlyError(e)));
          mainSendPort.send(
            ErrorMessage(path: src, message: _friendlyError(e)),
          );
        }
      }
    }

    String mapDestination(String srcPath, String dest) {
      final sep = Platform.pathSeparator;
      final srcRoot = _findSourceRoot(srcPath, sourceRoots);
      if (srcRoot != null) {
        final srcName = srcRoot.split(sep).last;
        final relative = srcPath.substring(srcRoot.length);
        return '$dest$sep$srcName$relative';
      }
      final name = srcPath.split(sep).last;
      return '$dest$sep$name';
    }

    Future<bool> processCopyItem(String srcPath) async {
      var resolution =
          runtimeApplyAll ??
          runtimeResolutions[srcPath] ??
          resolutions[srcPath];
      if (resolution == ConflictResolution.skip) {
        return true;
      }

      var dstPath = mapDestination(srcPath, destination!);
      if (resolution == ConflictResolution.rename) {
        dstPath = _uniqueName(dstPath);
      }

      try {
        final type = FileSystemEntity.typeSync(srcPath);
        if (type == FileSystemEntityType.notFound) {
          errors.add(TaskError(path: srcPath, message: t.errors.notFound));
          return true;
        } else if (type == FileSystemEntityType.file) {
          final targetExists =
              FileSystemEntity.typeSync(dstPath) !=
              FileSystemEntityType.notFound;
          if (resolution != ConflictResolution.overwrite && targetExists) {
            final size = File(srcPath).lengthSync();
            final targetStat = FileStat.statSync(dstPath);
            final sourceStat = FileStat.statSync(srcPath);
            final info = ConflictInfo(
              sourcePath: srcPath,
              targetPath: dstPath,
              name: srcPath.split(Platform.pathSeparator).last,
              sourceSize: size,
              targetSize: targetStat.size,
              sourceModified: sourceStat.modified,
              targetModified: targetStat.modified,
            );
            pendingConflicts[srcPath] = info;
            emitPrompt(info);
            return false;
          }

          final dstDir = dstPath.substring(
            0,
            dstPath.lastIndexOf(Platform.pathSeparator),
          );
          if (!Directory(dstDir).existsSync()) {
            Directory(dstDir).createSync(recursive: true);
          }

          final size = File(srcPath).lengthSync();
          _copyFileSync(File(srcPath), dstPath);
          processedBytes += size;
        } else if (type == FileSystemEntityType.directory) {
          if (!Directory(dstPath).existsSync()) {
            Directory(dstPath).createSync(recursive: true);
          }
        }
      } catch (e) {
        errors.add(TaskError(path: srcPath, message: _friendlyError(e)));
      }
      return true;
    }

    Future<void> executeCopy() async {
      for (final c in conflicts) {
        pendingConflicts[c.sourcePath] = c;
        if (!resolutions.containsKey(c.sourcePath)) {
          emitPrompt(c);
        }
      }

      for (final srcPath in allPaths) {
        if (cancelled) break;

        if (pendingConflicts.containsKey(srcPath) &&
            runtimeApplyAll == null &&
            runtimeResolutions[srcPath] == null &&
            resolutions[srcPath] == null) {
          continue;
        }

        final handled = await processCopyItem(srcPath);
        if (handled) {
          pendingConflicts.remove(srcPath);
          processedFiles++;
          maybeReport(srcPath.split(Platform.pathSeparator).last);
          if (processedFiles % 4 == 0) {
            await Future.delayed(Duration.zero);
          }
        }
      }

      while (pendingConflicts.isNotEmpty && !cancelled) {
        final resolvable = pendingConflicts.keys
            .where(
              (s) =>
                  runtimeApplyAll != null ||
                  runtimeResolutions[s] != null ||
                  resolutions[s] != null,
            )
            .toList();
        if (resolvable.isEmpty) {
          decisionWaker = Completer<void>();
          await decisionWaker!.future;
          continue;
        }
        for (final srcPath in resolvable) {
          if (cancelled) break;
          final handled = await processCopyItem(srcPath);
          if (handled) {
            pendingConflicts.remove(srcPath);
            processedFiles++;
            maybeReport(srcPath.split(Platform.pathSeparator).last);
            if (processedFiles % 4 == 0) {
              await Future.delayed(Duration.zero);
            }
          }
        }
      }

      mainSendPort.send(TaskDoneMessage(cancelled: cancelled, errors: errors));
      workerReceivePort.close();
    }

    workerReceivePort.listen((msg) {
      try {
        if (msg is StartCommand) {
          destination = msg.destination;
          for (final src in msg.sources) {
            sourceRoots.add(src);
            scanEntity(src, destination!);
          }
          mainSendPort.send(
            PreScanResultMessage(
              totalFiles: totalFiles,
              totalBytes: totalBytes,
              allPaths: allPaths,
              conflicts: conflicts,
            ),
          );
        } else if (msg is ExecuteCommand) {
          resolutions = msg.resolutions;
          executeCopy().catchError((e, st) {
            mainSendPort.send(
              TaskDoneMessage(
                cancelled: cancelled,
                errors: [
                  ...errors,
                  TaskError(path: '', message: e.toString()),
                ],
              ),
            );
            workerReceivePort.close();
          });
        } else if (msg is ConflictDecisionCommand) {
          if (msg.applyToAll) runtimeApplyAll = msg.resolution;
          runtimeResolutions[msg.sourcePath] = msg.resolution;
          wakeDecisions();
        } else if (msg is CancelCommand) {
          cancelled = true;
          wakeDecisions();
        }
      } catch (e) {
        mainSendPort.send(
          TaskDoneMessage(
            cancelled: cancelled,
            errors: [
              ...errors,
              TaskError(path: '', message: e.toString()),
            ],
          ),
        );
        workerReceivePort.close();
      }
    });
  }

  static void moveWorker(List<dynamic> args) {
    final mainSendPort = args[0] as SendPort;
    final workerReceivePort = ReceivePort();
    mainSendPort.send(workerReceivePort.sendPort);

    bool cancelled = false;
    final allPaths = <String>[];
    final sourceRoots = <String>{};
    final visitedDirs = <String>{};
    int totalFiles = 0;
    final conflicts = <ConflictInfo>[];
    Map<String, ConflictResolution> resolutions = {};
    final runtimeResolutions = <String, ConflictResolution>{};
    final pendingConflicts = <String, ConflictInfo>{};
    final promptedSet = <String>{};
    ConflictResolution? runtimeApplyAll;
    Completer<void>? decisionWaker;
    final errors = <TaskError>[];
    String? destination;
    int processedFiles = 0;
    var lastReport = DateTime.now();

    void emitPrompt(ConflictInfo info) {
      if (promptedSet.add(info.sourcePath)) {
        mainSendPort.send(ConflictPromptMessage(conflict: info));
      }
    }

    void wakeDecisions() {
      final w = decisionWaker;
      decisionWaker = null;
      w?.complete();
    }

    void maybeReport(String currentFile) {
      final now = DateTime.now();
      if (now.difference(lastReport).inMilliseconds > 50 ||
          processedFiles % 100 == 0) {
        mainSendPort.send(
          ProgressMessage(
            processedFiles: processedFiles,
            processedBytes: 0,
            currentFile: currentFile,
          ),
        );
        lastReport = now;
      }
    }

    void scanEntity(String src, String dest) {
      final name = src.split(Platform.pathSeparator).last;
      final targetPath = '$dest${Platform.pathSeparator}$name';

      final type = FileSystemEntity.typeSync(src);
      if (type == FileSystemEntityType.notFound) {
        errors.add(TaskError(path: src, message: t.errors.notFound));
        mainSendPort.send(ErrorMessage(path: src, message: t.errors.notFound));
        return;
      }
      if (type == FileSystemEntityType.directory) {
        allPaths.add(src);
        totalFiles++;
        _scanDirForMove(
          Directory(src),
          targetPath,
          visitedDirs,
          (path, conflict) {
            allPaths.add(path);
            totalFiles++;
            if (conflict != null) conflicts.add(conflict);
          },
          (errorPath, errorMsg) {
            errors.add(TaskError(path: errorPath, message: errorMsg));
            mainSendPort.send(ErrorMessage(path: errorPath, message: errorMsg));
          },
        );
      } else {
        try {
          allPaths.add(src);
          totalFiles++;
          if (FileSystemEntity.typeSync(targetPath) !=
              FileSystemEntityType.notFound) {
            final targetStat = FileStat.statSync(targetPath);
            final sourceStat = FileStat.statSync(src);
            conflicts.add(
              ConflictInfo(
                sourcePath: src,
                targetPath: targetPath,
                name: name,
                sourceSize: sourceStat.size,
                targetSize: targetStat.size,
                sourceModified: sourceStat.modified,
                targetModified: targetStat.modified,
              ),
            );
          }
        } catch (e) {
          errors.add(TaskError(path: src, message: _friendlyError(e)));
          mainSendPort.send(
            ErrorMessage(path: src, message: _friendlyError(e)),
          );
        }
      }
    }

    String mapDestination(String srcPath, String dest) {
      final sep = Platform.pathSeparator;
      final srcRoot = _findSourceRoot(srcPath, sourceRoots);
      if (srcRoot != null) {
        final srcName = srcRoot.split(sep).last;
        final relative = srcPath.substring(srcRoot.length);
        return '$dest$sep$srcName$relative';
      }
      final name = srcPath.split(sep).last;
      return '$dest$sep$name';
    }

    ConflictInfo buildConflictInfo(String src, String dst) {
      final targetStat = FileStat.statSync(dst);
      final sourceStat = FileStat.statSync(src);
      return ConflictInfo(
        sourcePath: src,
        targetPath: dst,
        name: src.split(Platform.pathSeparator).last,
        sourceSize: sourceStat.size,
        targetSize: targetStat.size,
        sourceModified: sourceStat.modified,
        targetModified: targetStat.modified,
      );
    }

    Future<bool> processMoveItem(String srcPath) async {
      var resolution =
          runtimeApplyAll ??
          runtimeResolutions[srcPath] ??
          resolutions[srcPath];
      if (resolution == ConflictResolution.skip) {
        return true;
      }

      var dstPath = mapDestination(srcPath, destination!);
      if (resolution == ConflictResolution.rename) {
        dstPath = _uniqueName(dstPath);
      }

      try {
        if (resolution != ConflictResolution.overwrite &&
            FileSystemEntity.typeSync(dstPath) !=
                FileSystemEntityType.notFound) {
          final info = buildConflictInfo(srcPath, dstPath);
          pendingConflicts[srcPath] = info;
          emitPrompt(info);
          return false;
        }
        await _moveEntity(srcPath, dstPath, () => cancelled, null);
      } catch (e) {
        errors.add(TaskError(path: srcPath, message: _friendlyError(e)));
      }
      return true;
    }

    Future<void> executeMove() async {
      for (final c in conflicts) {
        pendingConflicts[c.sourcePath] = c;
        if (!resolutions.containsKey(c.sourcePath)) {
          emitPrompt(c);
        }
      }

      final canFastPath =
          sourceRoots.length == 1 && allPaths.length > 1 && conflicts.isEmpty;

      if (canFastPath) {
        final src = sourceRoots.first;
        final name = src.split(Platform.pathSeparator).last;
        var dstPath = '$destination${Platform.pathSeparator}$name';
        var resolution =
            runtimeApplyAll ?? runtimeResolutions[src] ?? resolutions[src];

        if (resolution == ConflictResolution.skip) {
          mainSendPort.send(
            TaskDoneMessage(cancelled: cancelled, errors: errors),
          );
          workerReceivePort.close();
          return;
        }
        if (resolution == ConflictResolution.rename) {
          dstPath = _uniqueName(dstPath);
        }
        try {
          if (!cancelled) {
            if (resolution != ConflictResolution.overwrite &&
                FileSystemEntity.typeSync(dstPath) !=
                    FileSystemEntityType.notFound) {
              final info = buildConflictInfo(src, dstPath);
              pendingConflicts[src] = info;
              emitPrompt(info);
              while (!cancelled &&
                  runtimeApplyAll == null &&
                  runtimeResolutions[src] == null) {
                decisionWaker = Completer<void>();
                await decisionWaker!.future;
              }
              if (cancelled) {
                mainSendPort.send(
                  TaskDoneMessage(cancelled: cancelled, errors: errors),
                );
                workerReceivePort.close();
                return;
              }
              resolution = runtimeApplyAll ?? runtimeResolutions[src];
              pendingConflicts.remove(src);
              if (resolution == ConflictResolution.skip) {
                mainSendPort.send(
                  TaskDoneMessage(cancelled: cancelled, errors: errors),
                );
                workerReceivePort.close();
                return;
              }
              if (resolution == ConflictResolution.rename) {
                dstPath = _uniqueName(dstPath);
              }
            }
            await _moveEntity(src, dstPath, () => cancelled, (current) {
              processedFiles++;
              maybeReport(current);
            });
            if (!cancelled) processedFiles = totalFiles;
          }
        } catch (e) {
          errors.add(TaskError(path: src, message: _friendlyError(e)));
        }
      } else {
        for (final srcPath in allPaths) {
          if (cancelled) break;

          if (pendingConflicts.containsKey(srcPath) &&
              runtimeApplyAll == null &&
              runtimeResolutions[srcPath] == null &&
              resolutions[srcPath] == null) {
            continue;
          }

          final handled = await processMoveItem(srcPath);
          if (handled) {
            pendingConflicts.remove(srcPath);
            processedFiles++;
            maybeReport(srcPath.split(Platform.pathSeparator).last);
            if (processedFiles % 4 == 0) {
              await Future.delayed(Duration.zero);
            }
          }
        }

        while (pendingConflicts.isNotEmpty && !cancelled) {
          final resolvable = pendingConflicts.keys
              .where(
                (s) =>
                    runtimeApplyAll != null ||
                    runtimeResolutions[s] != null ||
                    resolutions[s] != null,
              )
              .toList();
          if (resolvable.isEmpty) {
            decisionWaker = Completer<void>();
            await decisionWaker!.future;
            continue;
          }
          for (final srcPath in resolvable) {
            if (cancelled) break;
            final handled = await processMoveItem(srcPath);
            if (handled) {
              pendingConflicts.remove(srcPath);
              processedFiles++;
              maybeReport(srcPath.split(Platform.pathSeparator).last);
              if (processedFiles % 4 == 0) {
                await Future.delayed(Duration.zero);
              }
            }
          }
        }
      }

      mainSendPort.send(TaskDoneMessage(cancelled: cancelled, errors: errors));
      workerReceivePort.close();
    }

    workerReceivePort.listen((msg) {
      try {
        if (msg is StartCommand) {
          destination = msg.destination;
          for (final src in msg.sources) {
            sourceRoots.add(src);
            scanEntity(src, destination!);
          }
          mainSendPort.send(
            PreScanResultMessage(
              totalFiles: totalFiles,
              totalBytes: null,
              allPaths: allPaths,
              conflicts: conflicts,
            ),
          );
        } else if (msg is ExecuteCommand) {
          resolutions = msg.resolutions;
          executeMove().catchError((e, st) {
            mainSendPort.send(
              TaskDoneMessage(
                cancelled: cancelled,
                errors: [
                  ...errors,
                  TaskError(path: '', message: e.toString()),
                ],
              ),
            );
            workerReceivePort.close();
          });
        } else if (msg is ConflictDecisionCommand) {
          if (msg.applyToAll) runtimeApplyAll = msg.resolution;
          runtimeResolutions[msg.sourcePath] = msg.resolution;
          wakeDecisions();
        } else if (msg is CancelCommand) {
          cancelled = true;
          wakeDecisions();
        }
      } catch (e) {
        mainSendPort.send(
          TaskDoneMessage(
            cancelled: cancelled,
            errors: [
              ...errors,
              TaskError(path: '', message: e.toString()),
            ],
          ),
        );
        workerReceivePort.close();
      }
    });
  }

  static void deleteWorker(List<dynamic> args) {
    final mainSendPort = args[0] as SendPort;
    final workerReceivePort = ReceivePort();
    mainSendPort.send(workerReceivePort.sendPort);

    bool cancelled = false;
    List<String> allPaths = [];
    int totalFiles = 0;
    List<TaskError> errors = [];
    int processedFiles = 0;
    var lastReport = DateTime.now();

    void maybeReport(String currentFile) {
      final now = DateTime.now();
      if (now.difference(lastReport).inMilliseconds > 50 ||
          processedFiles % 100 == 0) {
        mainSendPort.send(
          ProgressMessage(
            processedFiles: processedFiles,
            processedBytes: 0,
            currentFile: currentFile,
          ),
        );
        lastReport = now;
      }
    }

    void scanForDelete(List<String> sources) {
      final visited = <String>{};
      void walk(String dirPath) {
        final resolved = _resolveCanonical(dirPath);
        if (!visited.add(resolved)) return;
        try {
          for (final entity in Directory(
            dirPath,
          ).listSync(followLinks: false)) {
            final entType = FileSystemEntity.typeSync(
              entity.path,
              followLinks: false,
            );
            if (entType == FileSystemEntityType.directory) {
              walk(entity.path);
            }
            allPaths.add(entity.path);
            totalFiles++;
          }
        } catch (e) {
          errors.add(TaskError(path: dirPath, message: _friendlyError(e)));
          mainSendPort.send(
            ErrorMessage(path: dirPath, message: _friendlyError(e)),
          );
        }
      }

      for (final src in sources) {
        final type = FileSystemEntity.typeSync(src, followLinks: false);
        if (type == FileSystemEntityType.notFound) {
          errors.add(TaskError(path: src, message: t.errors.notFound));
          mainSendPort.send(
            ErrorMessage(path: src, message: t.errors.notFound),
          );
        } else if (type == FileSystemEntityType.directory) {
          walk(src);
          allPaths.add(src);
          totalFiles++;
        } else {
          allPaths.add(src);
          totalFiles++;
        }
      }
    }

    Future<void> executeDelete() async {
      final sorted = List<String>.from(allPaths);
      sorted.sort((a, b) => b.length.compareTo(a.length));

      for (final path in sorted) {
        if (cancelled) break;

        try {
          final type = FileSystemEntity.typeSync(path, followLinks: false);
          if (type == FileSystemEntityType.link) {
            Link(path).deleteSync();
          } else if (type == FileSystemEntityType.directory) {
            Directory(path).deleteSync(recursive: false);
          } else if (type == FileSystemEntityType.file) {
            File(path).deleteSync();
          }
        } catch (e) {
          errors.add(TaskError(path: path, message: _friendlyError(e)));
        }

        processedFiles++;
        maybeReport(path.split(Platform.pathSeparator).last);
        if (processedFiles % 4 == 0) {
          await Future.delayed(Duration.zero);
        }
      }

      mainSendPort.send(TaskDoneMessage(cancelled: cancelled, errors: errors));
      workerReceivePort.close();
    }

    workerReceivePort.listen((msg) {
      try {
        if (msg is StartCommand) {
          scanForDelete(msg.sources);
          mainSendPort.send(
            PreScanResultMessage(
              totalFiles: totalFiles,
              totalBytes: null,
              allPaths: allPaths,
              conflicts: [],
            ),
          );
        } else if (msg is ExecuteCommand) {
          executeDelete().catchError((e, st) {
            mainSendPort.send(
              TaskDoneMessage(
                cancelled: cancelled,
                errors: [
                  ...errors,
                  TaskError(path: '', message: e.toString()),
                ],
              ),
            );
            workerReceivePort.close();
          });
        } else if (msg is CancelCommand) {
          cancelled = true;
        }
      } catch (e) {
        mainSendPort.send(
          TaskDoneMessage(
            cancelled: cancelled,
            errors: [
              ...errors,
              TaskError(path: '', message: e.toString()),
            ],
          ),
        );
        workerReceivePort.close();
      }
    });
  }

  static void _copyFileSync(File src, String dstPath) {
    const chunkSize = 1024 * 1024;
    final input = src.openSync(mode: FileMode.read);
    final output = File(dstPath).openSync(mode: FileMode.write);
    try {
      while (true) {
        final chunk = input.readSync(chunkSize);
        if (chunk.isEmpty) break;
        output.writeFromSync(chunk);
      }
    } finally {
      input.closeSync();
      output.closeSync();
    }
  }

  static void _scanDirForCopy(
    Directory dir,
    String dest,
    Set<String> visited,
    void Function(String path, int bytes, ConflictInfo? conflict) onFile,
    void Function(String path, String message) onError,
  ) {
    final canonical = _resolveCanonical(dir.path);
    if (!visited.add(canonical)) return;
    if (!Directory(dest).existsSync()) {
      Directory(dest).createSync(recursive: true);
    }
    try {
      for (final entity in dir.listSync(followLinks: false)) {
        final name = entity.path.split(Platform.pathSeparator).last;
        final targetPath = '$dest${Platform.pathSeparator}$name';
        if (entity is Link) {
          continue;
        } else if (entity is Directory) {
          _scanDirForCopy(entity, targetPath, visited, onFile, onError);
        } else if (entity is File) {
          try {
            final size = entity.lengthSync();
            ConflictInfo? conflict;
            if (FileSystemEntity.typeSync(targetPath) !=
                FileSystemEntityType.notFound) {
              final targetStat = FileStat.statSync(targetPath);
              final sourceStat = FileStat.statSync(entity.path);
              conflict = ConflictInfo(
                sourcePath: entity.path,
                targetPath: targetPath,
                name: name,
                sourceSize: size,
                targetSize: targetStat.size,
                sourceModified: sourceStat.modified,
                targetModified: targetStat.modified,
              );
            }
            onFile(entity.path, size, conflict);
          } catch (e) {
            onError(entity.path, _friendlyError(e));
          }
        }
      }
    } catch (e) {
      onError(dir.path, _friendlyError(e));
    }
  }

  static void _scanDirForMove(
    Directory dir,
    String dest,
    Set<String> visited,
    void Function(String path, ConflictInfo? conflict) onEntry,
    void Function(String path, String message) onError,
  ) {
    final canonical = _resolveCanonical(dir.path);
    if (!visited.add(canonical)) return;
    if (!Directory(dest).existsSync()) {
      Directory(dest).createSync(recursive: true);
    }
    try {
      for (final entity in dir.listSync(followLinks: false)) {
        final name = entity.path.split(Platform.pathSeparator).last;
        final targetPath = '$dest${Platform.pathSeparator}$name';
        if (entity is Link) {
          onEntry(entity.path, null);
          continue;
        } else if (entity is Directory) {
          _scanDirForMove(entity, targetPath, visited, onEntry, onError);
        } else {
          try {
            ConflictInfo? conflict;
            if (FileSystemEntity.typeSync(targetPath) !=
                FileSystemEntityType.notFound) {
              final targetStat = FileStat.statSync(targetPath);
              final sourceStat = FileStat.statSync(entity.path);
              conflict = ConflictInfo(
                sourcePath: entity.path,
                targetPath: targetPath,
                name: name,
                sourceSize: sourceStat.size,
                targetSize: targetStat.size,
                sourceModified: sourceStat.modified,
                targetModified: targetStat.modified,
              );
            }
            onEntry(entity.path, conflict);
          } catch (e) {
            onError(entity.path, _friendlyError(e));
          }
        }
      }
    } catch (e) {
      onError(dir.path, _friendlyError(e));
    }
  }

  static String? _findSourceRoot(String path, Set<String> sourceRoots) {
    final sep = Platform.pathSeparator;
    String? best;
    for (final candidate in sourceRoots) {
      if (path == candidate) {
        return candidate;
      }
      if (path.startsWith(candidate) &&
          path.length > candidate.length &&
          path[candidate.length] == sep) {
        if (best == null || candidate.length > best.length) {
          best = candidate;
        }
      }
    }
    return best;
  }

  static Future<void> _moveEntity(
    String src,
    String dst,
    bool Function() isCancelled,
    void Function(String currentName)? onProgress,
  ) async {
    final type = FileSystemEntity.typeSync(src, followLinks: false);
    if (type == FileSystemEntityType.link) {
      final target = Link(src).targetSync();
      Link(dst).createSync(target);
      Link(src).deleteSync();
      return;
    }
    if (type == FileSystemEntityType.directory) {
      try {
        Directory(src).renameSync(dst);
      } on FileSystemException {
        await _copyDirectory(
          Directory(src),
          Directory(dst),
          isCancelled,
          onProgress,
        );
        if (isCancelled()) return;
        Directory(src).deleteSync(recursive: true);
      }
    } else {
      try {
        File(src).renameSync(dst);
      } on FileSystemException {
        _copyFileSync(File(src), dst);
        if (isCancelled()) {
          return;
        }
        File(src).deleteSync();
      }
    }
  }

  static Future<void> _copyDirectory(
    Directory src,
    Directory dst,
    bool Function() isCancelled,
    void Function(String currentName)? onProgress,
  ) async {
    if (!dst.existsSync()) dst.createSync(recursive: true);
    int counter = 0;
    for (final entity in src.listSync(followLinks: false)) {
      if (isCancelled()) return;
      final name = entity.path.split(Platform.pathSeparator).last;
      final newPath = '${dst.path}${Platform.pathSeparator}$name';
      if (entity is Link) {
        try {
          Link(newPath).createSync(entity.targetSync());
        } catch (_) {}
      } else if (entity is Directory) {
        await _copyDirectory(
          entity,
          Directory(newPath),
          isCancelled,
          onProgress,
        );
      } else if (entity is File) {
        _copyFileSync(entity, newPath);
        onProgress?.call(name);
      }
      if ((++counter & 0xF) == 0) {
        await Future.delayed(Duration.zero);
      }
    }
  }

  static String _resolveCanonical(String path) {
    try {
      return File(path).resolveSymbolicLinksSync();
    } catch (_) {
      return path;
    }
  }

  static String _uniqueName(String path) {
    if (!File(path).existsSync() && !Directory(path).existsSync()) return path;
    final dir = path.substring(0, path.lastIndexOf(Platform.pathSeparator));
    final name = path.substring(path.lastIndexOf(Platform.pathSeparator) + 1);
    final dotIndex = name.lastIndexOf('.');
    for (int counter = 1; counter <= 10000; counter++) {
      final newName = dotIndex > 0
          ? '${name.substring(0, dotIndex)} ($counter)${name.substring(dotIndex)}'
          : '$name ($counter)';
      final newPath = '$dir${Platform.pathSeparator}$newName';
      if (!File(newPath).existsSync() && !Directory(newPath).existsSync()) {
        return newPath;
      }
    }
    return '$dir${Platform.pathSeparator}$name.${DateTime.now().microsecondsSinceEpoch}';
  }

  static String _friendlyError(Object e) {
    final msg = e.toString();
    if (e is FileSystemException) {
      if (msg.contains('Permission denied') ||
          msg.contains('errno = 13') ||
          msg.contains('Access is denied') ||
          msg.contains('ERROR_ACCESS_DENIED')) {
        return t.errors.permissionDenied;
      }
      if (msg.contains('No space left') ||
          msg.contains('errno = 28') ||
          msg.contains('ERROR_DISK_FULL') ||
          msg.contains('There is not enough space')) {
        return t.errors.noSpace;
      }
      if (msg.contains('Read-only file system') ||
          msg.contains('errno = 30') ||
          msg.contains('ERROR_WRITE_PROTECT')) {
        return t.errors.readOnly;
      }
      if (msg.contains('No such file') ||
          msg.contains('errno = 2') ||
          msg.contains('ERROR_FILE_NOT_FOUND') ||
          msg.contains('ERROR_PATH_NOT_FOUND') ||
          msg.contains('The system cannot find')) {
        return t.errors.notFound;
      }
      if (msg.contains('Directory not empty') ||
          msg.contains('errno = 39') ||
          msg.contains('ERROR_DIR_NOT_EMPTY')) {
        return t.errors.notEmpty;
      }
      if (msg.contains('cross-device') ||
          msg.contains('errno = 18') ||
          msg.contains('ERROR_NOT_SAME_DEVICE')) {
        return t.errors.crossDevice;
      }
      if (e.message.isNotEmpty) return e.message;
    }
    if (msg.length > 120) return '${msg.substring(0, 117)}...';
    return msg;
  }
}
