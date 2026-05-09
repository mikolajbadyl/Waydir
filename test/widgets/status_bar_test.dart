import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waydir/ui/theme/app_theme.dart';
import 'package:waydir/core/models/file_entry.dart';
import 'package:waydir/features/navigation/navigation_store.dart';
import 'package:waydir/features/navigation/status_bar.dart';
import 'package:waydir/features/operations/operation_store.dart';

void main() {
  Widget wrapWithTheme(Widget child) {
    return MaterialApp(
      theme: AppTheme.build(),
      home: Scaffold(body: child),
    );
  }

  group('StatusBar', () {
    testWidgets('displays item count', (tester) async {
      final store = NavigationStore(operationStore: OperationStore());
      store.files.value = [
        FileEntry(name: 'a', path: '/a', type: FileItemType.file, size: 0, modified: DateTime(2025)),
      ];

      await tester.pumpWidget(wrapWithTheme(StatusBar(store: store, operationStore: OperationStore())));
      await tester.pump();

      expect(find.text('1 items'), findsOneWidget);
    });

    testWidgets('displays folder and file counts', (tester) async {
      final store = NavigationStore(operationStore: OperationStore());
      store.files.value = [
        FileEntry(name: 'dir', path: '/dir', type: FileItemType.folder, size: 0, modified: DateTime(2025)),
        FileEntry(name: 'dir2', path: '/dir2', type: FileItemType.folder, size: 0, modified: DateTime(2025)),
        FileEntry(name: 'a.txt', path: '/a.txt', type: FileItemType.file, size: 0, modified: DateTime(2025)),
        FileEntry(name: 'b.txt', path: '/b.txt', type: FileItemType.file, size: 0, modified: DateTime(2025)),
        FileEntry(name: 'c.txt', path: '/c.txt', type: FileItemType.file, size: 0, modified: DateTime(2025)),
      ];

      await tester.pumpWidget(wrapWithTheme(StatusBar(store: store, operationStore: OperationStore())));
      await tester.pump();

      expect(find.text('2 folders, 3 files'), findsOneWidget);
    });

    testWidgets('hides selected count when none selected', (tester) async {
      final store = NavigationStore(operationStore: OperationStore());

      await tester.pumpWidget(wrapWithTheme(StatusBar(store: store, operationStore: OperationStore())));
      await tester.pump();

      expect(find.text('0 selected'), findsNothing);
    });

    testWidgets('shows selected count when items selected', (tester) async {
      final store = NavigationStore(operationStore: OperationStore());
      store.selectedPaths.value = {'/a', '/b', '/c'};

      await tester.pumpWidget(wrapWithTheme(StatusBar(store: store, operationStore: OperationStore())));
      await tester.pump();

      expect(find.text('3 selected'), findsOneWidget);
    });

    testWidgets('displays app name', (tester) async {
      final store = NavigationStore(operationStore: OperationStore());

      await tester.pumpWidget(wrapWithTheme(StatusBar(store: store, operationStore: OperationStore())));
      await tester.pump();

      expect(find.text('Waydir'), findsOneWidget);
    });

    testWidgets('handles zero items', (tester) async {
      final store = NavigationStore(operationStore: OperationStore());

      await tester.pumpWidget(wrapWithTheme(StatusBar(store: store, operationStore: OperationStore())));
      await tester.pump();

      expect(find.text('0 items'), findsOneWidget);
      expect(find.text('0 folders, 0 files'), findsOneWidget);
    });
  });
}
