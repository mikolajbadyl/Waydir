import 'package:signals/signals.dart';
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

  late final activePane = computed(() {
    final list = panes.value;
    final idx = activePaneIndex.value;
    if (idx < 0 || idx >= list.length) return list.first;
    return list[idx];
  });

  late final activeStore = computed(() {
    return activePane.value.tabs.activeTab.value.store;
  });

  void Function()? _persistDisposer;

  ShellStore({required this.operationStore, required this.notificationStore}) {
    _restoreFromSettings();
    _wirePersistence();
  }

  void _restoreFromSettings() {
    final s = SettingsStore.instance;
    final saved = s.sessionPanes.value;
    if (saved.isEmpty) {
      panes.value = [PaneStore(operationStore: operationStore)];
      return;
    }
    final restored = <PaneStore>[];
    for (int i = 0; i < saved.length; i++) {
      restored.add(
        PaneStore.fromPaths(
          operationStore: operationStore,
          paths: saved[i],
          activeTabIndex: i < s.sessionPaneActiveTabs.value.length
              ? s.sessionPaneActiveTabs.value[i]
              : 0,
        ),
      );
    }
    panes.value = restored;
    splitRatio.value = s.sessionSplitRatio.value.clamp(0.2, 0.8);
    final wantDual = s.sessionIsDual.value && restored.length >= 2;
    isDual.value = wantDual;
    final activeIdx = s.sessionActivePaneIndex.value;
    activePaneIndex.value = wantDual
        ? activeIdx.clamp(0, restored.length - 1)
        : 0;
  }

  void _wirePersistence() {
    final s = SettingsStore.instance;
    _persistDisposer = effect(() {
      final paneList = panes.value;
      final tabPaths = <List<String>>[];
      final tabActiveIdx = <int>[];
      for (final pane in paneList) {
        final tabs = pane.tabs.tabs.value;
        tabPaths.add(tabs.map((t) => t.store.currentPath.value).toList());
        tabActiveIdx.add(pane.tabs.activeIndex.value);
      }
      s.sessionPanes.value = tabPaths;
      s.sessionPaneActiveTabs.value = tabActiveIdx;
      s.sessionIsDual.value = isDual.value;
      s.sessionSplitRatio.value = splitRatio.value;
      s.sessionActivePaneIndex.value = activePaneIndex.value;
    });
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
    final currentPath = activeStore.value.currentPath.value;
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
    for (final pane in panes.value) {
      pane.dispose();
    }
  }
}
