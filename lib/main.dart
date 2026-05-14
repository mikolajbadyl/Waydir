import 'dart:async';
import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app/app_info.dart';
import 'app/waydir_app.dart';
import 'core/fs/fs_worker_pool.dart';
import 'core/settings/settings_store.dart';
import 'i18n/strings.g.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  LocaleSettings.useDeviceLocale();
  try {
    await initializeDateFormatting();
  } catch (_) {}
  unawaited(FsWorkerPool.instance.ensureStarted());
  await SettingsStore.instance.load();
  await AppInfo.init();
  runApp(TranslationProvider(child: const WaydirApp()));

  doWhenWindowReady(() {
    appWindow.minSize = const Size(700, 450);
    appWindow.size = const Size(1100, 700);
    appWindow.alignment = Alignment.center;
    appWindow.title = '';
    appWindow.show();
  });
}
