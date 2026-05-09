import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:waydir/ui/theme/app_theme.dart';
import 'package:waydir/features/navigation/navigation_store.dart';
import 'package:waydir/features/operations/operation_store.dart';
import 'package:waydir/features/navigation/toolbar.dart';
import 'package:waydir/ui/overlays/notification_store.dart';

void main() {
  Widget wrapWithTheme(Widget child) {
    return MaterialApp(
      theme: AppTheme.build(),
      home: Scaffold(body: child),
    );
  }

  NavigationStore createStore({String path = '/home/user/Documents'}) {
    final store = NavigationStore(
      operationStore: OperationStore(),
      initialPath: path,
    );
    return store;
  }

  NavigationStore createStoreWithHistory({
    String path = '/home/user/Documents',
    bool canGoBack = true,
    bool canGoForward = true,
  }) {
    final store = NavigationStore(
      operationStore: OperationStore(),
      initialPath: path,
    );
    if (canGoBack && canGoForward) {
      store.history.value = ['/home', '/home/user', path];
      store.historyIndex.value = 1;
    }
    return store;
  }

  NotificationStore createNotificationStore() => NotificationStore();

  group('Toolbar', () {
    testWidgets('renders navigation icons', (tester) async {
      final store = createStoreWithHistory();

      await tester.pumpWidget(
        wrapWithTheme(
          Toolbar(store: store, notificationStore: createNotificationStore()),
        ),
      );

      expect(find.byIcon(PhosphorIconsRegular.arrowLeft), findsOneWidget);
      expect(find.byIcon(PhosphorIconsRegular.arrowRight), findsOneWidget);
      expect(find.byIcon(PhosphorIconsRegular.arrowUp), findsOneWidget);
      expect(find.byIcon(PhosphorIconsRegular.arrowClockwise), findsOneWidget);
    });

    testWidgets('renders breadcrumb path segments', (tester) async {
      final store = createStore();

      await tester.pumpWidget(
        wrapWithTheme(
          Toolbar(store: store, notificationStore: createNotificationStore()),
        ),
      );

      expect(find.text('/'), findsOneWidget);
      expect(find.text('home'), findsOneWidget);
      expect(find.text('user'), findsOneWidget);
      expect(find.text('Documents'), findsOneWidget);
    });

    testWidgets('renders view options button', (tester) async {
      final store = createStore(path: '/home');

      await tester.pumpWidget(
        wrapWithTheme(
          Toolbar(store: store, notificationStore: createNotificationStore()),
        ),
      );

      expect(find.byIcon(PhosphorIconsRegular.sliders), findsOneWidget);
    });

    testWidgets('view options panel toggles showHidden', (tester) async {
      final store = createStore(path: '/home');
      expect(store.showHidden.value, false);

      await tester.pumpWidget(
        wrapWithTheme(
          Toolbar(store: store, notificationStore: createNotificationStore()),
        ),
      );

      await tester.tap(find.byIcon(PhosphorIconsRegular.sliders));
      await tester.pumpAndSettle();

      expect(find.text('Show Hidden Files'), findsOneWidget);

      await tester.tap(find.text('Show Hidden Files'));
      await tester.pumpAndSettle();

      expect(store.showHidden.value, true);
    });

    testWidgets('renders breadcrumb separators', (tester) async {
      final store = createStore();

      await tester.pumpWidget(
        wrapWithTheme(
          Toolbar(store: store, notificationStore: createNotificationStore()),
        ),
      );

      expect(find.byIcon(PhosphorIconsRegular.caretRight), findsNWidgets(3));
    });
  });
}
