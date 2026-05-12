// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _terminalMeta = const VerificationMeta(
    'terminal',
  );
  @override
  late final GeneratedColumn<String> terminal = GeneratedColumn<String>(
    'terminal',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('auto'),
  );
  static const VerificationMeta _terminalCustomCommandMeta =
      const VerificationMeta('terminalCustomCommand');
  @override
  late final GeneratedColumn<String> terminalCustomCommand =
      GeneratedColumn<String>(
        'terminal_custom_command',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant(''),
      );
  static const VerificationMeta _isDualMeta = const VerificationMeta('isDual');
  @override
  late final GeneratedColumn<bool> isDual = GeneratedColumn<bool>(
    'is_dual',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_dual" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _splitRatioMeta = const VerificationMeta(
    'splitRatio',
  );
  @override
  late final GeneratedColumn<double> splitRatio = GeneratedColumn<double>(
    'split_ratio',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.5),
  );
  static const VerificationMeta _activePaneIndexMeta = const VerificationMeta(
    'activePaneIndex',
  );
  @override
  late final GeneratedColumn<int> activePaneIndex = GeneratedColumn<int>(
    'active_pane_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    terminal,
    terminalCustomCommand,
    isDual,
    splitRatio,
    activePaneIndex,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('terminal')) {
      context.handle(
        _terminalMeta,
        terminal.isAcceptableOrUnknown(data['terminal']!, _terminalMeta),
      );
    }
    if (data.containsKey('terminal_custom_command')) {
      context.handle(
        _terminalCustomCommandMeta,
        terminalCustomCommand.isAcceptableOrUnknown(
          data['terminal_custom_command']!,
          _terminalCustomCommandMeta,
        ),
      );
    }
    if (data.containsKey('is_dual')) {
      context.handle(
        _isDualMeta,
        isDual.isAcceptableOrUnknown(data['is_dual']!, _isDualMeta),
      );
    }
    if (data.containsKey('split_ratio')) {
      context.handle(
        _splitRatioMeta,
        splitRatio.isAcceptableOrUnknown(data['split_ratio']!, _splitRatioMeta),
      );
    }
    if (data.containsKey('active_pane_index')) {
      context.handle(
        _activePaneIndexMeta,
        activePaneIndex.isAcceptableOrUnknown(
          data['active_pane_index']!,
          _activePaneIndexMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      terminal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}terminal'],
      )!,
      terminalCustomCommand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}terminal_custom_command'],
      )!,
      isDual: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_dual'],
      )!,
      splitRatio: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}split_ratio'],
      )!,
      activePaneIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}active_pane_index'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final int id;
  final String terminal;
  final String terminalCustomCommand;
  final bool isDual;
  final double splitRatio;
  final int activePaneIndex;
  const AppSetting({
    required this.id,
    required this.terminal,
    required this.terminalCustomCommand,
    required this.isDual,
    required this.splitRatio,
    required this.activePaneIndex,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['terminal'] = Variable<String>(terminal);
    map['terminal_custom_command'] = Variable<String>(terminalCustomCommand);
    map['is_dual'] = Variable<bool>(isDual);
    map['split_ratio'] = Variable<double>(splitRatio);
    map['active_pane_index'] = Variable<int>(activePaneIndex);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      id: Value(id),
      terminal: Value(terminal),
      terminalCustomCommand: Value(terminalCustomCommand),
      isDual: Value(isDual),
      splitRatio: Value(splitRatio),
      activePaneIndex: Value(activePaneIndex),
    );
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      id: serializer.fromJson<int>(json['id']),
      terminal: serializer.fromJson<String>(json['terminal']),
      terminalCustomCommand: serializer.fromJson<String>(
        json['terminalCustomCommand'],
      ),
      isDual: serializer.fromJson<bool>(json['isDual']),
      splitRatio: serializer.fromJson<double>(json['splitRatio']),
      activePaneIndex: serializer.fromJson<int>(json['activePaneIndex']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'terminal': serializer.toJson<String>(terminal),
      'terminalCustomCommand': serializer.toJson<String>(terminalCustomCommand),
      'isDual': serializer.toJson<bool>(isDual),
      'splitRatio': serializer.toJson<double>(splitRatio),
      'activePaneIndex': serializer.toJson<int>(activePaneIndex),
    };
  }

  AppSetting copyWith({
    int? id,
    String? terminal,
    String? terminalCustomCommand,
    bool? isDual,
    double? splitRatio,
    int? activePaneIndex,
  }) => AppSetting(
    id: id ?? this.id,
    terminal: terminal ?? this.terminal,
    terminalCustomCommand: terminalCustomCommand ?? this.terminalCustomCommand,
    isDual: isDual ?? this.isDual,
    splitRatio: splitRatio ?? this.splitRatio,
    activePaneIndex: activePaneIndex ?? this.activePaneIndex,
  );
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      id: data.id.present ? data.id.value : this.id,
      terminal: data.terminal.present ? data.terminal.value : this.terminal,
      terminalCustomCommand: data.terminalCustomCommand.present
          ? data.terminalCustomCommand.value
          : this.terminalCustomCommand,
      isDual: data.isDual.present ? data.isDual.value : this.isDual,
      splitRatio: data.splitRatio.present
          ? data.splitRatio.value
          : this.splitRatio,
      activePaneIndex: data.activePaneIndex.present
          ? data.activePaneIndex.value
          : this.activePaneIndex,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('id: $id, ')
          ..write('terminal: $terminal, ')
          ..write('terminalCustomCommand: $terminalCustomCommand, ')
          ..write('isDual: $isDual, ')
          ..write('splitRatio: $splitRatio, ')
          ..write('activePaneIndex: $activePaneIndex')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    terminal,
    terminalCustomCommand,
    isDual,
    splitRatio,
    activePaneIndex,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.id == this.id &&
          other.terminal == this.terminal &&
          other.terminalCustomCommand == this.terminalCustomCommand &&
          other.isDual == this.isDual &&
          other.splitRatio == this.splitRatio &&
          other.activePaneIndex == this.activePaneIndex);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<int> id;
  final Value<String> terminal;
  final Value<String> terminalCustomCommand;
  final Value<bool> isDual;
  final Value<double> splitRatio;
  final Value<int> activePaneIndex;
  const AppSettingsCompanion({
    this.id = const Value.absent(),
    this.terminal = const Value.absent(),
    this.terminalCustomCommand = const Value.absent(),
    this.isDual = const Value.absent(),
    this.splitRatio = const Value.absent(),
    this.activePaneIndex = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    this.id = const Value.absent(),
    this.terminal = const Value.absent(),
    this.terminalCustomCommand = const Value.absent(),
    this.isDual = const Value.absent(),
    this.splitRatio = const Value.absent(),
    this.activePaneIndex = const Value.absent(),
  });
  static Insertable<AppSetting> custom({
    Expression<int>? id,
    Expression<String>? terminal,
    Expression<String>? terminalCustomCommand,
    Expression<bool>? isDual,
    Expression<double>? splitRatio,
    Expression<int>? activePaneIndex,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (terminal != null) 'terminal': terminal,
      if (terminalCustomCommand != null)
        'terminal_custom_command': terminalCustomCommand,
      if (isDual != null) 'is_dual': isDual,
      if (splitRatio != null) 'split_ratio': splitRatio,
      if (activePaneIndex != null) 'active_pane_index': activePaneIndex,
    });
  }

  AppSettingsCompanion copyWith({
    Value<int>? id,
    Value<String>? terminal,
    Value<String>? terminalCustomCommand,
    Value<bool>? isDual,
    Value<double>? splitRatio,
    Value<int>? activePaneIndex,
  }) {
    return AppSettingsCompanion(
      id: id ?? this.id,
      terminal: terminal ?? this.terminal,
      terminalCustomCommand:
          terminalCustomCommand ?? this.terminalCustomCommand,
      isDual: isDual ?? this.isDual,
      splitRatio: splitRatio ?? this.splitRatio,
      activePaneIndex: activePaneIndex ?? this.activePaneIndex,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (terminal.present) {
      map['terminal'] = Variable<String>(terminal.value);
    }
    if (terminalCustomCommand.present) {
      map['terminal_custom_command'] = Variable<String>(
        terminalCustomCommand.value,
      );
    }
    if (isDual.present) {
      map['is_dual'] = Variable<bool>(isDual.value);
    }
    if (splitRatio.present) {
      map['split_ratio'] = Variable<double>(splitRatio.value);
    }
    if (activePaneIndex.present) {
      map['active_pane_index'] = Variable<int>(activePaneIndex.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('id: $id, ')
          ..write('terminal: $terminal, ')
          ..write('terminalCustomCommand: $terminalCustomCommand, ')
          ..write('isDual: $isDual, ')
          ..write('splitRatio: $splitRatio, ')
          ..write('activePaneIndex: $activePaneIndex')
          ..write(')'))
        .toString();
  }
}

class $SessionTabsTable extends SessionTabs
    with TableInfo<$SessionTabsTable, SessionTab> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionTabsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _paneIndexMeta = const VerificationMeta(
    'paneIndex',
  );
  @override
  late final GeneratedColumn<int> paneIndex = GeneratedColumn<int>(
    'pane_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tabIndexMeta = const VerificationMeta(
    'tabIndex',
  );
  @override
  late final GeneratedColumn<int> tabIndex = GeneratedColumn<int>(
    'tab_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    paneIndex,
    tabIndex,
    path,
    isActive,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'session_tabs';
  @override
  VerificationContext validateIntegrity(
    Insertable<SessionTab> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('pane_index')) {
      context.handle(
        _paneIndexMeta,
        paneIndex.isAcceptableOrUnknown(data['pane_index']!, _paneIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_paneIndexMeta);
    }
    if (data.containsKey('tab_index')) {
      context.handle(
        _tabIndexMeta,
        tabIndex.isAcceptableOrUnknown(data['tab_index']!, _tabIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_tabIndexMeta);
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SessionTab map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionTab(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      paneIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pane_index'],
      )!,
      tabIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tab_index'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
    );
  }

  @override
  $SessionTabsTable createAlias(String alias) {
    return $SessionTabsTable(attachedDatabase, alias);
  }
}

class SessionTab extends DataClass implements Insertable<SessionTab> {
  final int id;
  final int paneIndex;
  final int tabIndex;
  final String path;
  final bool isActive;
  const SessionTab({
    required this.id,
    required this.paneIndex,
    required this.tabIndex,
    required this.path,
    required this.isActive,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['pane_index'] = Variable<int>(paneIndex);
    map['tab_index'] = Variable<int>(tabIndex);
    map['path'] = Variable<String>(path);
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  SessionTabsCompanion toCompanion(bool nullToAbsent) {
    return SessionTabsCompanion(
      id: Value(id),
      paneIndex: Value(paneIndex),
      tabIndex: Value(tabIndex),
      path: Value(path),
      isActive: Value(isActive),
    );
  }

  factory SessionTab.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionTab(
      id: serializer.fromJson<int>(json['id']),
      paneIndex: serializer.fromJson<int>(json['paneIndex']),
      tabIndex: serializer.fromJson<int>(json['tabIndex']),
      path: serializer.fromJson<String>(json['path']),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'paneIndex': serializer.toJson<int>(paneIndex),
      'tabIndex': serializer.toJson<int>(tabIndex),
      'path': serializer.toJson<String>(path),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  SessionTab copyWith({
    int? id,
    int? paneIndex,
    int? tabIndex,
    String? path,
    bool? isActive,
  }) => SessionTab(
    id: id ?? this.id,
    paneIndex: paneIndex ?? this.paneIndex,
    tabIndex: tabIndex ?? this.tabIndex,
    path: path ?? this.path,
    isActive: isActive ?? this.isActive,
  );
  SessionTab copyWithCompanion(SessionTabsCompanion data) {
    return SessionTab(
      id: data.id.present ? data.id.value : this.id,
      paneIndex: data.paneIndex.present ? data.paneIndex.value : this.paneIndex,
      tabIndex: data.tabIndex.present ? data.tabIndex.value : this.tabIndex,
      path: data.path.present ? data.path.value : this.path,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionTab(')
          ..write('id: $id, ')
          ..write('paneIndex: $paneIndex, ')
          ..write('tabIndex: $tabIndex, ')
          ..write('path: $path, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, paneIndex, tabIndex, path, isActive);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionTab &&
          other.id == this.id &&
          other.paneIndex == this.paneIndex &&
          other.tabIndex == this.tabIndex &&
          other.path == this.path &&
          other.isActive == this.isActive);
}

class SessionTabsCompanion extends UpdateCompanion<SessionTab> {
  final Value<int> id;
  final Value<int> paneIndex;
  final Value<int> tabIndex;
  final Value<String> path;
  final Value<bool> isActive;
  const SessionTabsCompanion({
    this.id = const Value.absent(),
    this.paneIndex = const Value.absent(),
    this.tabIndex = const Value.absent(),
    this.path = const Value.absent(),
    this.isActive = const Value.absent(),
  });
  SessionTabsCompanion.insert({
    this.id = const Value.absent(),
    required int paneIndex,
    required int tabIndex,
    required String path,
    this.isActive = const Value.absent(),
  }) : paneIndex = Value(paneIndex),
       tabIndex = Value(tabIndex),
       path = Value(path);
  static Insertable<SessionTab> custom({
    Expression<int>? id,
    Expression<int>? paneIndex,
    Expression<int>? tabIndex,
    Expression<String>? path,
    Expression<bool>? isActive,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (paneIndex != null) 'pane_index': paneIndex,
      if (tabIndex != null) 'tab_index': tabIndex,
      if (path != null) 'path': path,
      if (isActive != null) 'is_active': isActive,
    });
  }

  SessionTabsCompanion copyWith({
    Value<int>? id,
    Value<int>? paneIndex,
    Value<int>? tabIndex,
    Value<String>? path,
    Value<bool>? isActive,
  }) {
    return SessionTabsCompanion(
      id: id ?? this.id,
      paneIndex: paneIndex ?? this.paneIndex,
      tabIndex: tabIndex ?? this.tabIndex,
      path: path ?? this.path,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (paneIndex.present) {
      map['pane_index'] = Variable<int>(paneIndex.value);
    }
    if (tabIndex.present) {
      map['tab_index'] = Variable<int>(tabIndex.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionTabsCompanion(')
          ..write('id: $id, ')
          ..write('paneIndex: $paneIndex, ')
          ..write('tabIndex: $tabIndex, ')
          ..write('path: $path, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $SessionTabsTable sessionTabs = $SessionTabsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    appSettings,
    sessionTabs,
  ];
}

typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      Value<String> terminal,
      Value<String> terminalCustomCommand,
      Value<bool> isDual,
      Value<double> splitRatio,
      Value<int> activePaneIndex,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      Value<String> terminal,
      Value<String> terminalCustomCommand,
      Value<bool> isDual,
      Value<double> splitRatio,
      Value<int> activePaneIndex,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get terminal => $composableBuilder(
    column: $table.terminal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get terminalCustomCommand => $composableBuilder(
    column: $table.terminalCustomCommand,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDual => $composableBuilder(
    column: $table.isDual,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get splitRatio => $composableBuilder(
    column: $table.splitRatio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get activePaneIndex => $composableBuilder(
    column: $table.activePaneIndex,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get terminal => $composableBuilder(
    column: $table.terminal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get terminalCustomCommand => $composableBuilder(
    column: $table.terminalCustomCommand,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDual => $composableBuilder(
    column: $table.isDual,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get splitRatio => $composableBuilder(
    column: $table.splitRatio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get activePaneIndex => $composableBuilder(
    column: $table.activePaneIndex,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get terminal =>
      $composableBuilder(column: $table.terminal, builder: (column) => column);

  GeneratedColumn<String> get terminalCustomCommand => $composableBuilder(
    column: $table.terminalCustomCommand,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDual =>
      $composableBuilder(column: $table.isDual, builder: (column) => column);

  GeneratedColumn<double> get splitRatio => $composableBuilder(
    column: $table.splitRatio,
    builder: (column) => column,
  );

  GeneratedColumn<int> get activePaneIndex => $composableBuilder(
    column: $table.activePaneIndex,
    builder: (column) => column,
  );
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> terminal = const Value.absent(),
                Value<String> terminalCustomCommand = const Value.absent(),
                Value<bool> isDual = const Value.absent(),
                Value<double> splitRatio = const Value.absent(),
                Value<int> activePaneIndex = const Value.absent(),
              }) => AppSettingsCompanion(
                id: id,
                terminal: terminal,
                terminalCustomCommand: terminalCustomCommand,
                isDual: isDual,
                splitRatio: splitRatio,
                activePaneIndex: activePaneIndex,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> terminal = const Value.absent(),
                Value<String> terminalCustomCommand = const Value.absent(),
                Value<bool> isDual = const Value.absent(),
                Value<double> splitRatio = const Value.absent(),
                Value<int> activePaneIndex = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                id: id,
                terminal: terminal,
                terminalCustomCommand: terminalCustomCommand,
                isDual: isDual,
                splitRatio: splitRatio,
                activePaneIndex: activePaneIndex,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;
typedef $$SessionTabsTableCreateCompanionBuilder =
    SessionTabsCompanion Function({
      Value<int> id,
      required int paneIndex,
      required int tabIndex,
      required String path,
      Value<bool> isActive,
    });
typedef $$SessionTabsTableUpdateCompanionBuilder =
    SessionTabsCompanion Function({
      Value<int> id,
      Value<int> paneIndex,
      Value<int> tabIndex,
      Value<String> path,
      Value<bool> isActive,
    });

class $$SessionTabsTableFilterComposer
    extends Composer<_$AppDatabase, $SessionTabsTable> {
  $$SessionTabsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get paneIndex => $composableBuilder(
    column: $table.paneIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tabIndex => $composableBuilder(
    column: $table.tabIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SessionTabsTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionTabsTable> {
  $$SessionTabsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get paneIndex => $composableBuilder(
    column: $table.paneIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tabIndex => $composableBuilder(
    column: $table.tabIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SessionTabsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionTabsTable> {
  $$SessionTabsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get paneIndex =>
      $composableBuilder(column: $table.paneIndex, builder: (column) => column);

  GeneratedColumn<int> get tabIndex =>
      $composableBuilder(column: $table.tabIndex, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);
}

class $$SessionTabsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionTabsTable,
          SessionTab,
          $$SessionTabsTableFilterComposer,
          $$SessionTabsTableOrderingComposer,
          $$SessionTabsTableAnnotationComposer,
          $$SessionTabsTableCreateCompanionBuilder,
          $$SessionTabsTableUpdateCompanionBuilder,
          (
            SessionTab,
            BaseReferences<_$AppDatabase, $SessionTabsTable, SessionTab>,
          ),
          SessionTab,
          PrefetchHooks Function()
        > {
  $$SessionTabsTableTableManager(_$AppDatabase db, $SessionTabsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionTabsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionTabsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionTabsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> paneIndex = const Value.absent(),
                Value<int> tabIndex = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
              }) => SessionTabsCompanion(
                id: id,
                paneIndex: paneIndex,
                tabIndex: tabIndex,
                path: path,
                isActive: isActive,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int paneIndex,
                required int tabIndex,
                required String path,
                Value<bool> isActive = const Value.absent(),
              }) => SessionTabsCompanion.insert(
                id: id,
                paneIndex: paneIndex,
                tabIndex: tabIndex,
                path: path,
                isActive: isActive,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SessionTabsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionTabsTable,
      SessionTab,
      $$SessionTabsTableFilterComposer,
      $$SessionTabsTableOrderingComposer,
      $$SessionTabsTableAnnotationComposer,
      $$SessionTabsTableCreateCompanionBuilder,
      $$SessionTabsTableUpdateCompanionBuilder,
      (
        SessionTab,
        BaseReferences<_$AppDatabase, $SessionTabsTable, SessionTab>,
      ),
      SessionTab,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$SessionTabsTableTableManager get sessionTabs =>
      $$SessionTabsTableTableManager(_db, _db.sessionTabs);
}
