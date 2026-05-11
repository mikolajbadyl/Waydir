import 'dart:convert';
import 'dart:io';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

import 'drive_model.dart';
import '../../core/platform/platform_paths.dart';

abstract class DriveService {
  Future<List<Drive>> getDrives();
  Future<void> mount(Drive drive);
  Future<void> mountWithPassword(Drive drive, String password);
  Future<void> unmount(Drive drive);

  factory DriveService() {
    if (PlatformPaths.isWindows) {
      return _WindowsDriveService();
    } else if (PlatformPaths.isLinux) {
      return _LinuxDriveService();
    } else {
      return _DummyDriveService();
    }
  }
}

class _WindowsDriveService implements DriveService {
  @override
  Future<List<Drive>> getDrives() async {
    final drives = <Drive>[];

    final bitMask = GetLogicalDrives();
    if (bitMask == 0) return drives;

    for (var i = 0; i < 26; i++) {
      if ((bitMask & (1 << i)) != 0) {
        final letter = String.fromCharCode(65 + i);
        final rootPath = '$letter:\\';
        final rootPathPtr = rootPath.toNativeUtf16();

        try {
          final driveType = GetDriveType(rootPathPtr);
          if (driveType == DRIVE_REMOVABLE || driveType == DRIVE_FIXED) {
            final volumeNameBuffer = wsalloc(MAX_PATH + 1);
            try {
              final result = GetVolumeInformation(
                rootPathPtr,
                volumeNameBuffer,
                MAX_PATH + 1,
                nullptr,
                nullptr,
                nullptr,
                nullptr,
                0,
              );

              String label = 'Local Disk';
              if (result != 0) {
                label = volumeNameBuffer.toDartString();
              }
              if (label.isEmpty) {
                label = driveType == DRIVE_REMOVABLE
                    ? 'USB Drive'
                    : 'Local Disk';
              }

              drives.add(
                Drive(
                  id: rootPath,
                  label: '$label ($letter:)',
                  mountPoint: rootPath,
                  isRemovable: driveType == DRIVE_REMOVABLE,
                  fsType:
                      null, // Windows specific FSType could be queried but isn't strictly needed here
                ),
              );
            } finally {
              free(volumeNameBuffer);
            }
          }
        } finally {
          free(rootPathPtr);
        }
      }
    }

    return drives;
  }

  @override
  Future<void> mount(Drive drive) async {
    // Windows auto-mounts drives
  }

  @override
  Future<void> mountWithPassword(Drive drive, String password) async {
    // Windows doesn't use standard sudo-like mount with password for basic volumes.
  }

  @override
  Future<void> unmount(Drive drive) async {
    if (!drive.isRemovable) return;
    final letter = drive.id.replaceAll(r'\', '');
    final script =
        '\$driveEject = New-Object -comObject Shell.Application; \$driveEject.Namespace(17).ParseName("$letter").InvokeVerb("Eject")';
    await Process.run('powershell', ['-NoProfile', '-Command', script]);
  }
}

class _LinuxDriveService implements DriveService {
  @override
  Future<List<Drive>> getDrives() async {
    try {
      final result = await Process.run('lsblk', [
        '-J',
        '-o',
        'NAME,TYPE,MOUNTPOINT,SIZE,LABEL,RM,FSTYPE,PARTTYPENAME',
      ]);

      if (result.exitCode != 0) return [];

      final data = jsonDecode(result.stdout as String) as Map<String, dynamic>;
      final devices = data['blockdevices'] as List<dynamic>? ?? [];

      final drives = <Drive>[];

      for (final device in devices) {
        _processDevice(device as Map<String, dynamic>, drives);
      }

      return drives;
    } catch (e) {
      return [];
    }
  }

  void _processDevice(Map<String, dynamic> device, List<Drive> drives) {
    final name = device['name'] as String?;
    final type = device['type'] as String?;
    final mountPoint = device['mountpoint'] as String?;
    final label = device['label'] as String?;
    final rm = device['rm'];
    final fstype = device['fstype'] as String?;
    final partTypeName = device['parttypename'] as String?;

    final isRemovable = rm == true || rm == '1' || rm == 1;

    // Add partitions or disks that have a filesystem
    if (type == 'part' || type == 'disk') {
      if (fstype != null && fstype != 'swap') {
        final lowerLabel = label?.toLowerCase() ?? '';
        final lowerPartType = partTypeName?.toLowerCase() ?? '';

        final isSystem =
            mountPoint == '/' ||
            mountPoint == '/home' ||
            mountPoint == '/boot' ||
            mountPoint == '/boot/efi' ||
            mountPoint == '[SWAP]';
        final isEfi =
            fstype == 'vfat' &&
            (lowerLabel == 'efi' || lowerLabel == 'efi system partition');
        final isRecoveryOrReserved =
            lowerPartType.contains('recovery') ||
            lowerPartType.contains('reserved') ||
            lowerPartType.contains('extended boot');

        // Skip loop devices, snaps, system partitions, EFI, and recovery/reserved partitions
        if (type != 'loop' &&
            !(mountPoint != null && mountPoint.contains('snap')) &&
            !isSystem &&
            !isEfi &&
            !isRecoveryOrReserved) {
          final id = '/dev/$name';
          // Check if it's already added
          if (!drives.any((d) => d.id == id)) {
            drives.add(
              Drive(
                id: id,
                label: label ?? name ?? 'Unknown Drive',
                mountPoint: mountPoint,
                isRemovable: isRemovable,
                fsType: fstype,
              ),
            );
          }
        }
      }
    }

    // Process children (partitions of a disk)
    final children = device['children'] as List<dynamic>?;
    if (children != null) {
      for (final child in children) {
        _processDevice(child as Map<String, dynamic>, drives);
      }
    }
  }

  @override
  Future<void> mount(Drive drive) async {
    final result = await Process.run('udisksctl', ['mount', '-b', drive.id]);
    if (result.exitCode != 0) {
      throw Exception(result.stderr.toString());
    }
  }

  @override
  Future<void> mountWithPassword(Drive drive, String password) async {
    final user = Platform.environment['USER'] ?? 'user';
    final safeLabel = drive.label.replaceAll(RegExp(r'\s+'), '_');
    final mnt = '/run/media/$user/$safeLabel';

    // Ensure the mount directory exists
    await Process.run('sh', [
      '-c',
      'echo "$password" | sudo -S mkdir -p "$mnt"',
    ]);

    String options = '';
    if (drive.fsType == 'ntfs' ||
        drive.fsType == 'vfat' ||
        drive.fsType == 'exfat') {
      try {
        final uidRes = await Process.run('id', ['-u']);
        final gidRes = await Process.run('id', ['-g']);
        if (uidRes.exitCode == 0 && gidRes.exitCode == 0) {
          options =
              '-o uid=${uidRes.stdout.toString().trim()},gid=${gidRes.stdout.toString().trim()}';
        }
      } catch (_) {}
    }

    final res = await Process.run('sh', [
      '-c',
      'echo "$password" | sudo -S mount $options "${drive.id}" "$mnt"',
    ]);

    if (res.exitCode != 0) {
      throw Exception(res.stderr.toString());
    }
  }

  @override
  Future<void> unmount(Drive drive) async {
    final result = await Process.run('udisksctl', ['unmount', '-b', drive.id]);
    if (result.exitCode != 0 &&
        result.stderr.toString().contains('Not mounted')) {
      // if standard udisksctl fails because it might have been mounted via sudo, try sudo umount
      // We can't prompt for password here gracefully without changing the API, but unmounting usually
      // works with udisksctl if it was mounted by it. If mounted by sudo, the user might need sudo again.
      // However, udisksctl normally handles even /run/media mounts.
    }
  }
}

class _DummyDriveService implements DriveService {
  @override
  Future<List<Drive>> getDrives() async => [];

  @override
  Future<void> mount(Drive drive) async {}

  @override
  Future<void> mountWithPassword(Drive drive, String password) async {}

  @override
  Future<void> unmount(Drive drive) async {}
}
