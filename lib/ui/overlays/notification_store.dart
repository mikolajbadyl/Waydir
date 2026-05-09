import 'dart:async';
import 'package:signals/signals.dart';
import '../../core/models/app_notification.dart';

class NotificationStore {
  final _notifications = signal<List<AppNotification>>([]);
  final _history = signal<List<AppNotification>>([]);
  final _timers = <String, Timer>{};
  int _counter = 0;

  Signal<List<AppNotification>> get notifications => _notifications;
  Signal<List<AppNotification>> get history => _history;

  static const int _softCap = 50;
  static const int _historyCap = 200;

  String add(AppNotification notification) {
    final id = notification.id.isEmpty ? '_n${_counter++}' : notification.id;
    final n = AppNotification(
      id: id,
      title: notification.title,
      message: notification.message,
      type: notification.type,
      autoDismissDuration: notification.autoDismissDuration,
      actions: notification.actions,
      icon: notification.icon,
      accentColor: notification.accentColor,
      timestamp: notification.timestamp,
    );

    _timers[id]?.cancel();
    _timers.remove(id);

    var current = _notifications.value;
    final existingIndex = current.indexWhere((e) => e.id == id);
    if (existingIndex >= 0) {
      final updated = List<AppNotification>.from(current);
      updated[existingIndex] = n;
      current = updated;
    } else {
      current = [...current, n];
    }

    while (current.length > _softCap) {
      final dropIndex = current.indexWhere(
        (e) => e.type == NotificationType.autoDismiss,
      );
      if (dropIndex < 0) break;
      final dropped = current[dropIndex];
      _timers.remove(dropped.id)?.cancel();
      current = List<AppNotification>.from(current)..removeAt(dropIndex);
    }

    _notifications.value = current;

    var h = _history.value;
    final hIdx = h.indexWhere((e) => e.id == id);
    if (hIdx >= 0) {
      h = List<AppNotification>.from(h);
      h[hIdx] = n;
    } else {
      h = [...h, n];
    }
    if (h.length > _historyCap) {
      h = h.sublist(h.length - _historyCap);
    }
    _history.value = h;

    if (n.type == NotificationType.autoDismiss) {
      _timers[id] = Timer(n.autoDismissDuration, () => dismiss(id));
    }

    return id;
  }

  void dismiss(String id) {
    _timers[id]?.cancel();
    _timers.remove(id);
    _notifications.value = _notifications.value
        .where((n) => n.id != id)
        .toList();
  }

  void clearHistory() {
    _history.value = [];
  }

  void removeFromHistory(String id) {
    _history.value = _history.value.where((n) => n.id != id).toList();
  }

  void dispose() {
    for (final t in _timers.values) {
      t.cancel();
    }
    _timers.clear();
    _notifications.dispose();
    _history.dispose();
  }
}
