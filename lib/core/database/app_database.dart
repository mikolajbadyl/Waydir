import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class AppSettings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get terminal => text().withDefault(const Constant('auto'))();
  TextColumn get terminalCustomCommand =>
      text().withDefault(const Constant(''))();
  BoolColumn get isDual => boolean().withDefault(const Constant(false))();
  RealColumn get splitRatio => real().withDefault(const Constant(0.5))();
  IntColumn get activePaneIndex => integer().withDefault(const Constant(0))();
}

class SessionTabs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get paneIndex => integer()();
  IntColumn get tabIndex => integer()();
  TextColumn get path => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(false))();
}

class Bookmarks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get orderIndex => integer()();
  TextColumn get label => text()();
  TextColumn get path => text().unique()();
}

@DriftDatabase(tables: [AppSettings, SessionTabs, Bookmarks])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(bookmarks);
      }
    },
  );

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'waydir.db',
      native: DriftNativeOptions(databaseDirectory: _getDatabaseDirectory),
    );
  }

  static Future<String> _getDatabaseDirectory() async {
    if (Platform.isLinux) {
      final xdg = Platform.environment['XDG_CONFIG_HOME'];
      final base = xdg != null && xdg.isNotEmpty
          ? xdg
          : p.join(Platform.environment['HOME'] ?? '', '.config');
      return p.join(base, 'waydir');
    }
    final dir = await getApplicationSupportDirectory();
    return dir.path;
  }

  Future<AppSetting> getSettings() {
    return (select(appSettings)..limit(1)).getSingleOrNull().then((row) {
      if (row != null) return row;
      return into(appSettings).insertReturning(AppSettingsCompanion.insert());
    });
  }

  Future<void> updateSettings(AppSettingsCompanion companion) {
    return (update(appSettings)..where((t) => t.id.equals(1))).write(companion);
  }

  Future<void> replaceTabs(List<SessionTabsCompanion> rows) async {
    await (delete(sessionTabs)).go();
    await batch((b) {
      b.insertAll(sessionTabs, rows);
    });
  }

  Future<List<SessionTab>> getTabs() {
    return (select(sessionTabs)..orderBy([
          (t) => OrderingTerm.asc(t.paneIndex),
          (t) => OrderingTerm.asc(t.tabIndex),
        ]))
        .get();
  }

  Future<List<Bookmark>> getBookmarks() {
    return (select(
      bookmarks,
    )..orderBy([(t) => OrderingTerm.asc(t.orderIndex)])).get();
  }

  Future<Bookmark?> getBookmarkByPath(String path) {
    return (select(
      bookmarks,
    )..where((t) => t.path.equals(path))).getSingleOrNull();
  }

  Future<Bookmark> addBookmark(String label, String path) async {
    final maxOrder = bookmarks.orderIndex.max();
    final row = await (selectOnly(
      bookmarks,
    )..addColumns([maxOrder])).getSingleOrNull();
    final nextOrder = (row?.read(maxOrder) ?? -1) + 1;
    return into(bookmarks).insertReturning(
      BookmarksCompanion.insert(
        orderIndex: nextOrder,
        label: label,
        path: path,
      ),
    );
  }

  Future<void> renameBookmark(int id, String label) {
    return (update(bookmarks)..where((t) => t.id.equals(id))).write(
      BookmarksCompanion(label: Value(label)),
    );
  }

  Future<void> deleteBookmark(int id) {
    return (delete(bookmarks)..where((t) => t.id.equals(id))).go();
  }
}
