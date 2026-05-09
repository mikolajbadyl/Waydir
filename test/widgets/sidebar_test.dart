import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:waydir/ui/theme/app_theme.dart';
import 'package:waydir/features/navigation/navigation_store.dart';
import 'package:waydir/features/operations/operation_store.dart';
import 'package:waydir/features/navigation/sidebar.dart';

void main() {
  final home = Platform.environment['HOME'] ?? '/';

  Widget wrapWithTheme(Widget child) {
    return MaterialApp(
      theme: AppTheme.build(),
      home: Scaffold(body: SizedBox(width: 200, height: 800, child: child)),
    );
  }

  NavigationStore createStore({String path = '/'}) {
    final store = NavigationStore(operationStore: OperationStore(), initialPath: path);
    return store;
  }

  group('Sidebar', () {
    testWidgets('renders both section headers', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        Sidebar(store: createStore(path: home)),
      ));

      expect(find.text('FAVORITES'), findsOneWidget);
      expect(find.text('DEVICES'), findsOneWidget);
    });

    testWidgets('renders all navigation items', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        Sidebar(store: createStore(path: home)),
      ));

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Desktop'), findsOneWidget);
      expect(find.text('Documents'), findsOneWidget);
      expect(find.text('Downloads'), findsOneWidget);
      expect(find.text('Pictures'), findsOneWidget);
      expect(find.text('Music'), findsOneWidget);
      expect(find.text('Videos'), findsOneWidget);
      expect(find.text('Root'), findsOneWidget);
    });

    testWidgets('renders correct icons', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        Sidebar(store: createStore(path: '/tmp')),
      ));

      expect(find.byIcon(PhosphorIconsRegular.house), findsOneWidget);
      expect(find.byIcon(PhosphorIconsRegular.desktop), findsOneWidget);
      expect(find.byIcon(PhosphorIconsRegular.notebook), findsOneWidget);
      expect(find.byIcon(PhosphorIconsRegular.downloadSimple), findsOneWidget);
      expect(find.byIcon(PhosphorIconsRegular.image), findsOneWidget);
      expect(find.byIcon(PhosphorIconsRegular.musicNote), findsOneWidget);
      expect(find.byIcon(PhosphorIconsRegular.videoCamera), findsOneWidget);
      expect(find.byIcon(PhosphorIconsRegular.hardDrives), findsOneWidget);
    });

    testWidgets('calls navigateTo when item tapped', (tester) async {
      final store = createStore(path: home);
      await tester.pumpWidget(wrapWithTheme(
        Sidebar(store: store),
      ));

      await tester.tap(find.text('Root'));
      expect(store.currentPath.value, '/');
    });

    testWidgets('highlights current path', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        Sidebar(store: createStore(path: home)),
      ));

      final homeText = tester.widgetList<Text>(find.text('Home')).first;
      expect(homeText.style?.fontWeight, FontWeight.w500);
    });

    testWidgets('does not highlight non-current path', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        Sidebar(store: createStore(path: home)),
      ));

      final desktopText = tester.widgetList<Text>(find.text('Desktop')).first;
      expect(desktopText.style?.fontWeight, isNot(equals(FontWeight.w500)));
    });
  });
}
