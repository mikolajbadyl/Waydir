import 'dart:async';
import 'dart:io';

class DirectoryWatcherService {
  static const _debounce = Duration(milliseconds: 150);

  StreamSubscription<FileSystemEvent>? _subscription;
  Timer? _debounceTimer;
  String? _watchedPath;
  void Function()? _onChange;

  void watch(String path, void Function() onChange) {
    if (_watchedPath == path && _subscription != null) {
      _onChange = onChange;
      return;
    }
    stop();
    _watchedPath = path;
    _onChange = onChange;
    try {
      final dir = Directory(path);
      if (!dir.existsSync()) return;
      _subscription = dir
          .watch(recursive: false)
          .listen(
            (_) {
              if (_watchedPath != path) return;
              _scheduleNotify();
            },
            onError: (_) {},
            cancelOnError: true,
          );
    } catch (_) {}
  }

  void _scheduleNotify() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounce, () {
      _onChange?.call();
    });
  }

  void stop() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _subscription?.cancel();
    _subscription = null;
    _watchedPath = null;
    _onChange = null;
  }

  void dispose() => stop();
}
