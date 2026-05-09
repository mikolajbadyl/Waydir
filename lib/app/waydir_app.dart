import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:signals/signals_flutter.dart';
import '../core/system/system_scale.dart';
import '../i18n/strings.g.dart';
import '../ui/theme/app_theme.dart';
import 'waydir_page.dart';

final waydirNavigatorKey = GlobalKey<NavigatorState>();

class WaydirApp extends StatelessWidget {
  const WaydirApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: t.app.title,
      navigatorKey: waydirNavigatorKey,
      locale: TranslationProvider.of(context).flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      builder: (context, child) {
        final scale = SystemScale.instance.effectiveScale.watch(context);
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(textScaler: TextScaler.linear(scale)),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const WaydirPage(),
    );
  }
}
