import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:signals/signals.dart';

import '../settings/settings_store.dart';

class SystemScale {
  static final SystemScale instance = SystemScale._();
  SystemScale._();

  static const _channel = MethodChannel('waydir/system_scale');
  static const _events = EventChannel('waydir/system_scale/events');

  final systemScale = signal<double>(1.0);
  late final Computed<double> effectiveScale = computed(() {
    final override = SettingsStore.instance.uiScale.value;
    final base = systemScale.value;
    if (override <= 0) return base;
    return override;
  });

  StreamSubscription<dynamic>? _sub;
  bool _started = false;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    if (!_supported) return;
    try {
      final v = await _channel.invokeMethod<double>('getScale');
      if (v != null && v > 0) systemScale.value = _clamp(v);
    } catch (_) {}
    try {
      _sub = _events.receiveBroadcastStream().listen((event) {
        if (event is num && event > 0) {
          systemScale.value = _clamp(event.toDouble());
        }
      }, onError: (_) {});
    } catch (_) {}
  }

  bool get _supported =>
      Platform.isLinux || Platform.isWindows || Platform.isMacOS;

  double _clamp(double v) => v.clamp(0.5, 4.0);

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }
}
