import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:signals/signals.dart';

class SettingsStore {
  static final SettingsStore instance = SettingsStore._();

  SettingsStore._();

  final terminal = signal<String>('auto');
  final terminalCustomCommand = signal<String>('');
  // 0 = auto (follow system); otherwise explicit multiplier (e.g. 1.0, 1.25).
  final uiScale = signal<double>(0);

  // Session state.
  final sessionIsDual = signal<bool>(false);
  final sessionSplitRatio = signal<double>(0.5);
  final sessionActivePaneIndex = signal<int>(0);
  final sessionPanes = signal<List<List<String>>>([]);
  final sessionPaneActiveTabs = signal<List<int>>([]);

  File? _file;
  bool _loaded = false;
  Timer? _saveDebounce;
  final _disposers = <void Function()>[];

  Future<void> load() async {
    if (_loaded) return;
    _file = await _resolveConfigFile();
    final file = _file!;
    if (await file.exists()) {
      try {
        final content = await file.readAsString();
        if (content.trim().isNotEmpty) {
          final data = jsonDecode(content) as Map<String, dynamic>;
          _applyJson(data);
        }
      } catch (_) {}
    }
    _loaded = true;
    _wireAutoSave();
  }

  void _applyJson(Map<String, dynamic> data) {
    final t = data['terminal'];
    if (t is String && t.isNotEmpty) terminal.value = t;
    final tc = data['terminalCustomCommand'];
    if (tc is String) terminalCustomCommand.value = tc;
    final us = data['uiScale'];
    if (us is num) uiScale.value = us.toDouble();

    final session = data['session'];
    if (session is Map<String, dynamic>) {
      final dual = session['isDual'];
      if (dual is bool) sessionIsDual.value = dual;
      final ratio = session['splitRatio'];
      if (ratio is num) sessionSplitRatio.value = ratio.toDouble();
      final activeIdx = session['activePaneIndex'];
      if (activeIdx is num) sessionActivePaneIndex.value = activeIdx.toInt();
      final panes = session['panes'];
      if (panes is List) {
        sessionPanes.value = panes
            .whereType<List>()
            .map((e) => e.whereType<String>().toList())
            .toList();
      }
      final activeTabs = session['paneActiveTabs'];
      if (activeTabs is List) {
        sessionPaneActiveTabs.value =
            activeTabs.whereType<num>().map((e) => e.toInt()).toList();
      }
    }
  }

  Map<String, dynamic> _toJson() => {
        'terminal': terminal.value,
        'terminalCustomCommand': terminalCustomCommand.value,
        'uiScale': uiScale.value,
        'session': {
          'isDual': sessionIsDual.value,
          'splitRatio': sessionSplitRatio.value,
          'activePaneIndex': sessionActivePaneIndex.value,
          'panes': sessionPanes.value,
          'paneActiveTabs': sessionPaneActiveTabs.value,
        },
      };

  void _wireAutoSave() {
    _disposers.add(effect(() {
      terminal.value;
      terminalCustomCommand.value;
      uiScale.value;
      sessionIsDual.value;
      sessionSplitRatio.value;
      sessionActivePaneIndex.value;
      sessionPanes.value;
      sessionPaneActiveTabs.value;
      if (!_loaded) return;
      _scheduleSave();
    }));
  }

  void _scheduleSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 200), _save);
  }

  Future<void> _save() async {
    final file = _file;
    if (file == null) return;
    try {
      await file.parent.create(recursive: true);
      const encoder = JsonEncoder.withIndent('  ');
      await file.writeAsString('${encoder.convert(_toJson())}\n');
    } catch (_) {}
  }

  Future<File> _resolveConfigFile() async {
    if (Platform.isLinux) {
      final xdg = Platform.environment['XDG_CONFIG_HOME'];
      final base = xdg != null && xdg.isNotEmpty
          ? xdg
          : p.join(Platform.environment['HOME'] ?? '', '.config');
      return File(p.join(base, 'waydir', 'config.json'));
    }
    final dir = await getApplicationSupportDirectory();
    return File(p.join(dir.path, 'config.json'));
  }

  void dispose() {
    for (final d in _disposers) {
      d();
    }
    _disposers.clear();
    _saveDebounce?.cancel();
  }
}
