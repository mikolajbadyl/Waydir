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

@DriftDatabase(tables: [AppSettings, SessionTabs])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

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
}
