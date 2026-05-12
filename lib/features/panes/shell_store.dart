import 'dart:async';

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:signals/signals.dart';

import '../../core/database/app_database.dart';
import '../../core/platform/platform_paths.dart';
import '../../core/settings/settings_store.dart';
import '../navigation/navigation_store.dart';
import '../operations/operation_store.dart';
import '../../ui/overlays/notification_store.dart';
import 'pane_store.dart';

class ShellStore {
  final isDual = signal(false);
  final panes = signal<List<PaneStore>>([]);
  final activePaneIndex = signal(0);
  final splitRatio = signal(0.5);
  final OperationStore operationStore;
  final NotificationStore notificationStore;
  final ready = signal(false);

  late final activePane = computed(() {
    final list = panes.value;
    if (list.isEmpty) return null;
    final idx = activePaneIndex.value;
    if (idx < 0 || idx >= list.length) return list.first;
    return list[idx];
  });

  late final activeStore = computed(() {
    return activePane.value?.tabs.activeTab.value.store;
  });

  void Function()? _persistDisposer;
  Timer? _tabPersistDebounce;

  ShellStore({required this.operationStore, required this.notificationStore}) {
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final s = SettingsStore.instance;
    final db = s.db;

    final savedTabs = await db.getTabs();

    if (savedTabs.isEmpty) {
      batch(() {
        panes.value = [PaneStore(operationStore: operationStore)];
        ready.value = true;
      });
    } else {
      final paneMap = <int, List<String>>{};
      final activeMap = <int, int>{};
      for (final tab in savedTabs) {
        paneMap.putIfAbsent(tab.paneIndex, () => []);
        paneMap[tab.paneIndex]!.add(tab.path);
        if (tab.isActive) {
          activeMap[tab.paneIndex] = tab.tabIndex;
        }
      }

      final restored = <PaneStore>[];
      final maxPane = paneMap.keys.reduce((a, b) => a > b ? a : b);
      for (int i = 0; i <= maxPane; i++) {
        final paths = paneMap[i] ?? [];
        final validPaths = paths
            .where((p) => Directory(p).existsSync())
            .toList();
        restored.add(
          PaneStore.fromPaths(
            operationStore: operationStore,
            paths: validPaths.isEmpty ? [PlatformPaths.homePath] : validPaths,
            activeTabIndex: activeMap[i] ?? 0,
          ),
        );
      }

      final wantDual = s.sessionIsDual.value && restored.length >= 2;
      final activeIdx = s.sessionActivePaneIndex.value;
      batch(() {
        panes.value = restored;
        isDual.value = wantDual;
        splitRatio.value = s.sessionSplitRatio.value.clamp(0.2, 0.8);
        activePaneIndex.value = wantDual
            ? activeIdx.clamp(0, restored.length - 1)
            : 0;
        ready.value = true;
      });
    }

    _wirePersistence();
  }

  void _wirePersistence() {
    final s = SettingsStore.instance;
    _persistDisposer = effect(() {
      panes.value;
      for (final pane in panes.value) {
        pane.tabs.tabs.value;
        pane.tabs.activeIndex.value;
        for (final tab in pane.tabs.tabs.value) {
          tab.store.currentPath.value;
        }
      }
      s.sessionIsDual.value = isDual.value;
      s.sessionSplitRatio.value = splitRatio.value;
      s.sessionActivePaneIndex.value = activePaneIndex.value;
      _scheduleTabPersist();
    });
  }

  void _scheduleTabPersist() {
    _tabPersistDebounce?.cancel();
    _tabPersistDebounce = Timer(
      const Duration(milliseconds: 200),
      _persistTabs,
    );
  }

  Future<void> _persistTabs() async {
    try {
      final db = SettingsStore.instance.db;
      final paneList = panes.value;
      final rows = <SessionTabsCompanion>[];
      for (int p = 0; p < paneList.length; p++) {
        final tabs = paneList[p].tabs.tabs.value;
        final activeIdx = paneList[p].tabs.activeIndex.value;
        for (int t = 0; t < tabs.length; t++) {
          rows.add(
            SessionTabsCompanion.insert(
              paneIndex: p,
              tabIndex: t,
              path: tabs[t].store.currentPath.value,
              isActive: Value(t == activeIdx),
            ),
          );
        }
      }
      await db.replaceTabs(rows);
    } catch (_) {}
  }

  void toggleDual() {
    if (isDual.value) {
      exitDual();
    } else {
      enterDual();
    }
  }

  void enterDual() {
    if (isDual.value) return;
    final currentPath = activeStore.value!.currentPath.value;
    final secondPane = PaneStore(
      operationStore: operationStore,
      initialPath: currentPath,
    );
    batch(() {
      panes.value = [panes.value[0], secondPane];
      activePaneIndex.value = 0;
      isDual.value = true;
    });
  }

  void exitDual() {
    if (!isDual.value) return;
    final closing = panes.value[1];
    batch(() {
      activePaneIndex.value = 0;
      panes.value = [panes.value[0]];
      isDual.value = false;
    });
    closing.dispose();
  }

  void setActivePane(int index) {
    if (index >= 0 && index < panes.value.length) {
      activePaneIndex.value = index;
    }
  }

  void setSplitRatio(double ratio) {
    splitRatio.value = ratio.clamp(0.2, 0.8);
  }

  Iterable<NavigationStore> get allStores sync* {
    for (final pane in panes.value) {
      for (final tab in pane.tabs.tabs.value) {
        yield tab.store;
      }
    }
  }

  void dispose() {
    _persistDisposer?.call();
    _persistDisposer = null;
    _tabPersistDebounce?.cancel();
    for (final pane in panes.value) {
      pane.dispose();
    }
  }
}
