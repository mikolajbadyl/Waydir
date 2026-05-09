import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:waydir/ui/theme/app_theme.dart';
import 'package:waydir/core/models/file_entry.dart';
import 'package:waydir/features/files/file_view.dart';

void main() {
  final testFiles = [
    FileEntry(
      name: 'Documents',
      path: '/home/Documents',
      type: FileItemType.folder,
      size: 4096,
      modified: DateTime(2025, 1, 1),
    ),
    FileEntry(
      name: 'readme.md',
      path: '/home/readme.md',
      type: FileItemType.file,
      size: 2048,
      modified: DateTime(2025, 6, 15),
    ),
    FileEntry(
      name: 'photo.png',
      path: '/home/photo.png',
      type: FileItemType.file,
      size: 512000,
      modified: DateTime(2025, 3, 10),
    ),
  ];

  Widget wrapWithTheme(Widget child) {
    return MaterialApp(
      theme: AppTheme.build(),
      home: Scaffold(body: child),
    );
  }

  group('FileList', () {
    testWidgets('renders all file names', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          FileList(
            files: testFiles,
            currentPath: '/home',
            onSelect: (_) {},
            onOpen: (_) {},
          ),
        ),
      );

      expect(find.text('Documents'), findsOneWidget);
      expect(find.text('readme.md'), findsOneWidget);
      expect(find.text('photo.png'), findsOneWidget);
    });

    testWidgets('renders list header', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          FileList(
            files: testFiles,
            currentPath: '/home',
            onSelect: (_) {},
            onOpen: (_) {},
          ),
        ),
      );

      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Size'), findsOneWidget);
      expect(find.text('Modified'), findsOneWidget);
    });

    testWidgets('renders folder icon for folders', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          FileList(
            files: testFiles,
            currentPath: '/home',
            onSelect: (_) {},
            onOpen: (_) {},
          ),
        ),
      );

      expect(find.byIcon(PhosphorIconsFill.folder), findsOneWidget);
    });

    testWidgets('renders file type icons for files', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          FileList(
            files: testFiles,
            currentPath: '/home',
            onSelect: (_) {},
            onOpen: (_) {},
          ),
        ),
      );

      expect(find.byIcon(PhosphorIconsRegular.fileMd), findsOneWidget);
      expect(find.byIcon(PhosphorIconsRegular.fileImage), findsOneWidget);
    });

    testWidgets('shows empty state when no files', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          FileList(
            files: [],
            currentPath: '/home',
            onSelect: (_) {},
            onOpen: (_) {},
          ),
        ),
      );

      expect(find.text('Folder is empty'), findsOneWidget);
      expect(find.byIcon(PhosphorIconsRegular.folderOpen), findsOneWidget);
    });

    testWidgets('calls onSelect with correct entry on tap', (tester) async {
      FileSelectionEvent? selected;
      await tester.pumpWidget(
        wrapWithTheme(
          FileList(
            files: testFiles,
            currentPath: '/home',
            onSelect: (e) => selected = e,
            onOpen: (_) {},
          ),
        ),
      );

      await tester.tap(find.text('readme.md'));
      expect(selected, isNotNull);
      expect(selected!.entry, testFiles[1]);
      expect(selected!.index, 1);
    });

    testWidgets('shows -- size for folders', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          FileList(
            files: testFiles,
            currentPath: '/home',
            onSelect: (_) {},
            onOpen: (_) {},
          ),
        ),
      );

      expect(find.text('--'), findsOneWidget);
    });

    testWidgets('shows formatted size for files', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          FileList(
            files: testFiles,
            currentPath: '/home',
            onSelect: (_) {},
            onOpen: (_) {},
          ),
        ),
      );

      expect(find.text('2.0 KB'), findsOneWidget);
      expect(find.text('500.0 KB'), findsOneWidget);
    });

    testWidgets('shows selection state', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          FileList(
            files: testFiles,
            currentPath: '/home',
            onSelect: (_) {},
            onOpen: (_) {},
            selectedPaths: {'/home/readme.md'},
          ),
        ),
      );

      final nameWidget = tester.widget<Text>(find.text('readme.md'));
      expect(nameWidget.style?.fontWeight, FontWeight.w500);
    });

    testWidgets('calls onOpen on double tap', (tester) async {
      FileEntry? opened;
      await tester.pumpWidget(
        wrapWithTheme(
          FileList(
            files: testFiles,
            currentPath: '/home',
            onSelect: (_) {},
            onOpen: (e) => opened = e,
          ),
        ),
      );

      await tester.tap(find.text('Documents'));
      await tester.pump();
      await tester.tap(find.text('Documents'));
      await tester.pump();

      expect(opened, testFiles[0]);
    });

    testWidgets('calls onBackgroundTap when tapping empty area', (
      tester,
    ) async {
      var bgTapped = false;
      await tester.pumpWidget(
        wrapWithTheme(
          SizedBox(
            height: 400,
            child: FileList(
              files: testFiles,
              currentPath: '/home',
              onSelect: (_) {},
              onOpen: (_) {},
              onBackgroundTap: () => bgTapped = true,
            ),
          ),
        ),
      );

      await tester.tapAt(const Offset(50, 200));
      expect(bgTapped, isTrue);
    });
  });

  group('FileSelectionEvent', () {
    test('stores entry and index', () {
      final entry = testFiles[0];
      final event = FileSelectionEvent(entry: entry, index: 0);
      expect(event.entry, entry);
      expect(event.index, 0);
    });
  });
}
