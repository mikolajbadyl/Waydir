import 'dart:io';
import '../platform/platform_paths.dart';

enum FileItemType { folder, file }

class FileSelectionEvent {
  final FileEntry entry;
  final int index;

  const FileSelectionEvent({required this.entry, required this.index});
}

class FileEntry {
  final String name;
  final String path;
  final FileItemType type;
  final int size;
  final DateTime modified;

  const FileEntry({
    required this.name,
    required this.path,
    required this.type,
    required this.size,
    required this.modified,
  });

  factory FileEntry.fromFileSystemEntity(FileSystemEntity entity) {
    final stat = entity.statSync();
    return FileEntry(
      name: PlatformPaths.fileName(entity.path),
      path: entity.path,
      type: entity is Directory ? FileItemType.folder : FileItemType.file,
      size: stat.size,
      modified: stat.modified,
    );
  }

  String get extension {
    if (type == FileItemType.folder) return '';
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex < 0) return '';
    return name.substring(dotIndex + 1).toLowerCase();
  }

  bool get isHidden => name.startsWith('.');
}
