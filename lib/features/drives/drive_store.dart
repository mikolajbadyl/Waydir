import 'dart:async';
import 'package:signals/signals.dart';
import 'drive_model.dart';
import 'drive_service.dart';

class DriveStore {
  final drives = signal<List<Drive>>([]);
  final DriveService _service = DriveService();
  Timer? _timer;

  DriveStore() {
    _init();
  }

  void _init() {
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      _refresh();
    });
  }

  Future<void> _refresh() async {
    try {
      final updatedDrives = await _service.getDrives();
      drives.value = updatedDrives;
    } catch (_) {}
  }

  Future<void> mount(Drive drive) async {
    await _service.mount(drive);
    await _refresh();
  }

  Future<void> mountWithPassword(Drive drive, String password) async {
    await _service.mountWithPassword(drive, password);
    await _refresh();
  }

  Future<void> unmount(Drive drive) async {
    try {
      await _service.unmount(drive);
      await _refresh();
    } catch (_) {}
  }

  void dispose() {
    _timer?.cancel();
  }
}

final driveStore = DriveStore();
