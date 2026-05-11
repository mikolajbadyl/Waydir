import 'dart:async';

import 'package:drift/drift.dart';
import 'package:signals/signals.dart';

import '../database/app_database.dart';

class SettingsStore {
  static final SettingsStore instance = SettingsStore._();

  SettingsStore._();

  final terminal = signal<String>('auto');
  final terminalCustomCommand = signal<String>('');
  final sessionIsDual = signal<bool>(false);
  final sessionSplitRatio = signal<double>(0.5);
  final sessionActivePaneIndex = signal<int>(0);

  late final AppDatabase _db;
  bool _loaded = false;
  Timer? _saveDebounce;
  final _disposers = <void Function()>[];

  AppDatabase get db => _db;

  Future<void> load() async {
    if (_loaded) return;
    _db = AppDatabase();
    await _loadFromDb();
    _loaded = true;
    _wireAutoSave();
  }

  Future<void> _loadFromDb() async {
    final row = await _db.getSettings();
    terminal.value = row.terminal;
    terminalCustomCommand.value = row.terminalCustomCommand;
    sessionIsDual.value = row.isDual;
    sessionSplitRatio.value = row.splitRatio;
    sessionActivePaneIndex.value = row.activePaneIndex;
  }

  void _wireAutoSave() {
    _disposers.add(
      effect(() {
        terminal.value;
        terminalCustomCommand.value;
        sessionIsDual.value;
        sessionSplitRatio.value;
        sessionActivePaneIndex.value;
        if (!_loaded) return;
        _scheduleSave();
      }),
    );
  }

  void _scheduleSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 200), _save);
  }

  Future<void> _save() async {
    try {
      await _db.updateSettings(
        AppSettingsCompanion(
          terminal: Value(terminal.value),
          terminalCustomCommand: Value(terminalCustomCommand.value),
          isDual: Value(sessionIsDual.value),
          splitRatio: Value(sessionSplitRatio.value),
          activePaneIndex: Value(sessionActivePaneIndex.value),
        ),
      );
    } catch (_) {}
  }

  void dispose() {
    for (final d in _disposers) {
      d();
    }
    _disposers.clear();
    _saveDebounce?.cancel();
  }
}
