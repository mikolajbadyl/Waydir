import 'dart:async';
import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'app/waydir_app.dart';
import 'core/fs/fs_worker_pool.dart';
import 'core/settings/settings_store.dart';
import 'i18n/strings.g.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LocaleSettings.useDeviceLocale();
  unawaited(FsWorkerPool.instance.ensureStarted());
  await SettingsStore.instance.load();
  runApp(TranslationProvider(child: const WaydirApp()));

  doWhenWindowReady(() {
    appWindow.minSize = const Size(700, 450);
    appWindow.size = const Size(1100, 700);
    appWindow.alignment = Alignment.center;
    appWindow.title = '';
    appWindow.show();
  });
}
