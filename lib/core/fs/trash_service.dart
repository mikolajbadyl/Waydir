import 'dart:io';

import '../platform/platform_paths.dart';

abstract class TrashService {
  Future<void> trash(String path);

  static final TrashService instance = _create();

  static TrashService _create() {
    if (PlatformPaths.isLinux) return _LinuxTrashService();
    if (PlatformPaths.isMacOS) return _MacTrashService();
    if (PlatformPaths.isWindows) return _WindowsTrashService();
    return _NoopTrashService();
  }
}

Future<void> _runOrThrow(
  String executable,
  List<String> args, {
  String? fallbackError,
}) async {
  final result = await Process.run(executable, args);
  if (result.exitCode == 0) return;
  final stderr = result.stderr.toString().trim();
  throw Exception(
    stderr.isEmpty
        ? (fallbackError ?? '$executable failed (exit ${result.exitCode})')
        : stderr,
  );
}

class _LinuxTrashService implements TrashService {
  @override
  Future<void> trash(String path) => _runOrThrow('gio', [
    'trash',
    '--',
    path,
  ], fallbackError: 'gio trash failed');
}

class _MacTrashService implements TrashService {
  @override
  Future<void> trash(String path) {
    final escaped = path.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
    return _runOrThrow('osascript', [
      '-e',
      'tell application "Finder" to delete POSIX file "$escaped"',
    ]);
  }
}

class _WindowsTrashService implements TrashService {
  @override
  Future<void> trash(String path) {
    final escaped = path.replaceAll("'", "''");
    final script =
        "Add-Type -AssemblyName Microsoft.VisualBasic; "
        "if (Test-Path -LiteralPath '$escaped' -PathType Container) { "
        "[Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory("
        "'$escaped','OnlyErrorDialogs','SendToRecycleBin') } else { "
        "[Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile("
        "'$escaped','OnlyErrorDialogs','SendToRecycleBin') }";
    return _runOrThrow('powershell', ['-NoProfile', '-Command', script]);
  }
}

class _NoopTrashService implements TrashService {
  @override
  Future<void> trash(String path) async {
    throw UnsupportedError('Trash not supported on this platform');
  }
}
