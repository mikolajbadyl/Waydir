import 'dart:async';
import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:scaled_app/scaled_app.dart';
import 'app/waydir_app.dart';
import 'core/fs/fs_worker_pool.dart';
import 'core/settings/settings_store.dart';
import 'core/system/system_scale.dart';
import 'i18n/strings.g.dart';

void main() async {
  ScaledWidgetsFlutterBinding.ensureInitialized(scaleFactor: (_) => 1.0);
  LocaleSettings.useDeviceLocale();
  unawaited(FsWorkerPool.instance.ensureStarted());
  await SettingsStore.instance.load();
  await SystemScale.instance.start();
  runApp(TranslationProvider(child: const WaydirApp()));

  doWhenWindowReady(() {
    appWindow.titleBarStyle = TitleBarStyle.hidden;
    final s = SystemScale.instance.uiScale.value;
    appWindow.minSize = Size(700 * s, 450 * s);
    appWindow.size = Size(1100 * s, 700 * s);
    appWindow.alignment = Alignment.center;
    appWindow.title = '';
    appWindow.show();
  });
}
