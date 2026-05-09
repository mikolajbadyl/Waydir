import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:scaled_app/scaled_app.dart';
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
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).scale(),
        child: child ?? const SizedBox.shrink(),
      ),
      home: const WaydirPage(),
    );
  }
}
