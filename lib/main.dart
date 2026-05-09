import 'dart:async';
import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'app/waydir_app.dart';
import 'core/fs/fs_worker_pool.dart';
import 'core/settings/settings_store.dart';
import 'core/system/system_scale.dart';
import 'i18n/strings.g.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LocaleSettings.useDeviceLocale();
  unawaited(FsWorkerPool.instance.ensureStarted());
  await SettingsStore.instance.load();
  await SystemScale.instance.start();
  runApp(TranslationProvider(child: const WaydirApp()));

  doWhenWindowReady(() {
    final override = SettingsStore.instance.uiScale.value;
    final base = SystemScale.instance.systemScale.value;
    final s = (override > 0 ? override : base).clamp(0.5, 4.0);
    final initialSize = Size(1100 * s, 700 * s);
    appWindow.minSize = Size(700 * s, 450 * s);
    appWindow.size = initialSize;
    appWindow.alignment = Alignment.center;
    appWindow.title = '';
    appWindow.show();
  });
}
