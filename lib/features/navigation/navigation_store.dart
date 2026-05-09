import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:signals/signals.dart';
import '../../core/models/file_entry.dart';
import '../../core/clipboard/file_clipboard.dart';
import '../../core/fs/file_system_service.dart';
import '../../core/fs/directory_watcher_service.dart';
import '../../core/fs/recursive_search.dart';
import '../../core/keyboard/keyboard_shortcuts.dart';
import '../../i18n/strings.g.dart';
import '../operations/operation_store.dart';

enum ClipboardMode { copy, cut }

const String kPendingCreatePath = '__pending_create__';

class NavigationStore {
  final currentPath = signal('');
  final files = signal<List<FileEntry>>([]);
  final showHidden = signal(false);
  final selectedPaths = signal<Set<String>>({});
  final cursorIndex = signal(-1);
  final anchorIndex = signal(-1);
  final history = signal<List<String>>([]);
  final historyIndex = signal(0);
  final isLoading = signal(false);
  final clipboardPaths = signal<Set<String>>({});
  final clipboardMode = signal<ClipboardMode?>(null);
  final OperationStore operationStore;
  final loadError = signal<String?>(null);
  final renamingPath = signal<String?>(null);
  final renameError = signal<String?>(null);
  final pendingCreate = signal<FileEntry?>(null);
  int _loadToken = 0;
  final DirectoryWatcherService _watcher = DirectoryWatcherService();

  final searchActive = signal(false);
  final searchQuery = signal('');
  final searchRecursive = signal(false);
  final searchResults = signal<List<FileEntry>>([]);
  final isSearching = signal(false);
  final searchScannedDirs = signal(0);
  final searchTruncated = signal(false);
  final searchCurrentDir = signal<String?>(null);
  final searchFocusRequest = signal(0);
  final renameAttempt = signal(0);

  SearchHandle? _searchHandle;
  Timer? _searchDebounce;
  Timer? _searchUiFlush;
  List<FileEntry>? _pendingSearchResults;
  static const _kSearchLimit = 5000;
  static const _kSearchUiFlushMs = 250;

  late final canGoBack = computed(() => historyIndex.value > 0);
  late final canGoForward = computed(
    () => historyIndex.value < history.value.length - 1,
  );
  late final visibleFiles = computed(() {
    final pending = pendingCreate.value;
    if (searchActive.value && searchRecursive.value) {
      return pending != null
          ? [pending, ...searchResults.value]
          : searchResults.value;
    }
    var list = showHidden.value
        ? files.value
        : files.value.where((f) => !f.isHidden).toList();
    final q = searchQuery.value.trim().toLowerCase();
    if (searchActive.value && q.isNotEmpty) {
      list = list.where((f) => f.name.toLowerCase().contains(q)).toList();
    }
    return pending != null ? [pending, ...list] : list;
  });
  late final folderCount = computed(
    () => visibleFiles.value.where((f) => f.type == FileItemType.folder).length,
  );
  late final fileCount = computed(
    () => visibleFiles.value.where((f) => f.type == FileItemType.file).length,
  );
  late final totalItems = computed(() => visibleFiles.value.length);
  late final selectedCount = computed(() => selectedPaths.value.length);
  late final canPaste = computed(
    () => clipboardPaths.value.isNotEmpty && clipboardMode.value != null,
  );

  NavigationStore({required this.operationStore, String? initialPath}) {
    final startPath = initialPath ?? Platform.environment['HOME'] ?? '/';
    currentPath.value = startPath;
    history.value = [startPath];
    loadDirectory(startPath);
    _setupShowHiddenEffect();
  }

  void _setupShowHiddenEffect() {
    effect(() {
      showHidden.value;
      if (searchActive.value && searchRecursive.value) {
        _restartRecursiveSearch();
      }
    });
  }

  void openSearch({bool recursive = false}) {
    batch(() {
      searchActive.value = true;
      if (recursive) searchRecursive.value = true;
      searchFocusRequest.value = searchFocusRequest.value + 1;
    });
  }

  void closeSearch() {
    _searchDebounce?.cancel();
    _searchUiFlush?.cancel();
    _searchUiFlush = null;
    _pendingSearchResults = null;
    _searchHandle?.cancel();
    _searchHandle = null;
    batch(() {
      searchActive.value = false;
      searchRecursive.value = false;
      searchQuery.value = '';
      searchResults.value = [];
      isSearching.value = false;
      searchScannedDirs.value = 0;
      searchTruncated.value = false;
      searchCurrentDir.value = null;
      cursorIndex.value = -1;
      anchorIndex.value = -1;
    });
  }

  void setSearchQuery(String q) {
    batch(() {
      searchQuery.value = q;
      cursorIndex.value = -1;
      anchorIndex.value = -1;
    });
    _scheduleSearchRestart();
  }

  void toggleRecursive() {
    searchRecursive.value = !searchRecursive.value;
    _scheduleSearchRestart();
  }

  void _scheduleSearchRestart() {
    _searchDebounce?.cancel();
    if (searchRecursive.value) {
      _searchDebounce = Timer(
        const Duration(milliseconds: 250),
        _restartRecursiveSearch,
      );
      return;
    }
    _restartRecursiveSearch();
  }

  void _restartRecursiveSearch() {
    _searchHandle?.cancel();
    _searchHandle = null;
    _searchUiFlush?.cancel();
    _searchUiFlush = null;
    _pendingSearchResults = null;
    batch(() {
      searchResults.value = [];
      searchScannedDirs.value = 0;
      searchTruncated.value = false;
      searchCurrentDir.value = null;
      isSearching.value = false;
      cursorIndex.value = -1;
      anchorIndex.value = -1;
    });
    if (!searchActive.value || !searchRecursive.value) return;
    final q = searchQuery.value.trim();
    if (q.isEmpty) return;
    isSearching.value = true;
    final acc = <FileEntry>[];
    _searchHandle = RecursiveSearch.start(
      root: currentPath.value,
      query: q,
      includeHidden: showHidden.value,
      onBatch: (b) {
        acc.addAll(b);
        if (acc.length >= _kSearchLimit) {
          _searchUiFlush?.cancel();
          _searchUiFlush = null;
          _pendingSearchResults = null;
          batch(() {
            searchTruncated.value = true;
            searchResults.value = List.of(acc.take(_kSearchLimit));
            isSearching.value = false;
          });
          _searchHandle?.cancel();
          return;
        }
        _pendingSearchResults = acc;
        _scheduleSearchUiFlush();
      },
      onProgress: (n, currentDir) {
        batch(() {
          searchScannedDirs.value = n;
          if (currentDir != null) {
            searchCurrentDir.value = currentDir;
          }
        });
      },
      onDone: () {
        _searchUiFlush?.cancel();
        _searchUiFlush = null;
        if (_pendingSearchResults != null) {
          searchResults.value = List.of(_pendingSearchResults!);
          _pendingSearchResults = null;
        }
        batch(() {
          isSearching.value = false;
          searchCurrentDir.value = null;
        });
      },
      onError: (_) {
        _searchUiFlush?.cancel();
        _searchUiFlush = null;
        _pendingSearchResults = null;
        batch(() {
          isSearching.value = false;
          searchCurrentDir.value = null;
        });
      },
    );
  }

  void _scheduleSearchUiFlush() {
    if (_searchUiFlush?.isActive ?? false) return;
    _searchUiFlush = Timer(const Duration(milliseconds: _kSearchUiFlushMs), () {
      _searchUiFlush = null;
      final pending = _pendingSearchResults;
      if (pending == null) return;
      _pendingSearchResults = null;
      searchResults.value = List.of(pending);
    });
  }

  void navigateTo(String path, {bool addToHistory = true}) {
    closeSearch();
    if (addToHistory) {
      history.value = history.value.sublist(0, historyIndex.value + 1)
        ..add(path);
      historyIndex.value = history.value.length - 1;
    }
    batch(() {
      selectedPaths.value = {};
      cursorIndex.value = -1;
      anchorIndex.value = -1;
      currentPath.value = path;
    });
    loadDirectory(path);
  }

  void goBack() {
    if (!canGoBack.value) return;
    historyIndex.value--;
    navigateTo(history.value[historyIndex.value], addToHistory: false);
  }

  void goForward() {
    if (!canGoForward.value) return;
    historyIndex.value++;
    navigateTo(history.value[historyIndex.value], addToHistory: false);
  }

  void goUp() async {
    final parts = currentPath.value.split(Platform.pathSeparator)..removeLast();
    final parent = parts.isEmpty ? '/' : parts.join(Platform.pathSeparator);
    if (parent.isNotEmpty && await FileSystemService.directoryExists(parent)) {
      navigateTo(parent);
    }
  }

  Future<void> refresh() => loadDirectory(currentPath.value);

  Future<void> loadDirectory(String path) async {
    final token = ++_loadToken;
    isLoading.value = true;
    try {
      final entries = await FileSystemService.listDirectory(path);
      if (token != _loadToken) return;
      batch(() {
        files.value = entries;
        loadError.value = null;
        isLoading.value = false;
      });
      _watcher.watch(path, () => _onExternalChange(path));
    } catch (e) {
      if (token != _loadToken) return;
      batch(() {
        files.value = [];
        loadError.value = e is FileSystemException
            ? (e.message.isNotEmpty ? e.message : e.toString())
            : e.toString();
        isLoading.value = false;
      });
      _watcher.stop();
    }
  }

  void _onExternalChange(String path) async {
    if (path != currentPath.value) return;
    try {
      final entries = await FileSystemService.listDirectory(path);
      if (path != currentPath.value) return;
      _applyExternalChanges(entries);
    } catch (_) {}
  }

  void _applyExternalChanges(List<FileEntry> newEntries) {
    final newPaths = newEntries.map((e) => e.path).toSet();
    final filteredSelected = selectedPaths.value
        .where(newPaths.contains)
        .toSet();

    final visible = showHidden.value
        ? newEntries
        : newEntries.where((f) => !f.isHidden).toList();

    int newCursor = -1;
    if (cursorIndex.value >= 0 && cursorIndex.value < _vf.length) {
      final cursorPath = _vf[cursorIndex.value].path;
      newCursor = visible.indexWhere((e) => e.path == cursorPath);
    }
    int newAnchor = -1;
    if (anchorIndex.value >= 0 && anchorIndex.value < _vf.length) {
      final anchorPath = _vf[anchorIndex.value].path;
      newAnchor = visible.indexWhere((e) => e.path == anchorPath);
    }

    batch(() {
      files.value = newEntries;
      selectedPaths.value = filteredSelected;
      cursorIndex.value = newCursor;
      anchorIndex.value = newAnchor;
    });
  }

  void startRename() {
    final entries = selectedEntries;
    if (entries.length != 1) return;
    renamingPath.value = entries.first.path;
  }

  void startCreate({FileItemType type = FileItemType.folder}) {
    batch(() {
      pendingCreate.value = FileEntry(
        name: '',
        path: kPendingCreatePath,
        type: type,
        size: 0,
        modified: DateTime.now(),
      );
      renamingPath.value = kPendingCreatePath;
      renameError.value = null;
    });
  }

  void cancelRename() {
    batch(() {
      renamingPath.value = null;
      renameError.value = null;
      pendingCreate.value = null;
    });
  }

  void commitRename(String newName) {
    final oldPath = renamingPath.value;
    if (oldPath == null) return;

    final trimmed = newName.trim();
    if (trimmed.isEmpty) {
      cancelRename();
      return;
    }

    if (oldPath == kPendingCreatePath) {
      _commitCreate(trimmed);
      return;
    }

    final result = FileSystemService.rename(oldPath, trimmed);

    switch (result) {
      case RenameSuccess(:final newPath):
        batch(() {
          renamingPath.value = null;
          renameError.value = null;
          selectedPaths.value = {newPath};
        });
        if (searchActive.value && searchRecursive.value) {
          final updated = searchResults.value.map((e) {
            if (e.path != oldPath) return e;
            return FileEntry(
              name: newPath.split(Platform.pathSeparator).last,
              path: newPath,
              type: e.type,
              size: e.size,
              modified: e.modified,
            );
          }).toList();
          searchResults.value = updated;
          final idx = updated.indexWhere((f) => f.path == newPath);
          if (idx >= 0) {
            batch(() {
              cursorIndex.value = idx;
              anchorIndex.value = idx;
            });
          }
        } else {
          refresh();
          final idx = _vf.indexWhere((f) => f.path == newPath);
          if (idx >= 0) {
            batch(() {
              cursorIndex.value = idx;
              anchorIndex.value = idx;
            });
          }
        }
      case RenameAlreadyExists():
        renameError.value = t.toast.renameAlreadyExists(name: trimmed);
        renameAttempt.value = renameAttempt.value + 1;
      case RenameError(:final message):
        renameError.value = t.toast.renameError(message: message);
        renameAttempt.value = renameAttempt.value + 1;
      case RenameInvalidName():
        renameError.value = t.toast.renameInvalidName;
        renameAttempt.value = renameAttempt.value + 1;
      case RenameNoChange():
        batch(() {
          renamingPath.value = null;
          renameError.value = null;
        });
    }
  }

  Future<void> _commitCreate(String name) async {
    final pending = pendingCreate.value;
    if (pending == null) return;
    if (name.contains(Platform.pathSeparator) || name == '.' || name == '..') {
      renameError.value = t.toast.renameInvalidName;
      renameAttempt.value = renameAttempt.value + 1;
      return;
    }
    final dir = currentPath.value;
    final newPath = '$dir${Platform.pathSeparator}$name';
    if (FileSystemEntity.typeSync(newPath) != FileSystemEntityType.notFound) {
      renameError.value = t.toast.renameAlreadyExists(name: name);
      renameAttempt.value = renameAttempt.value + 1;
      return;
    }
    try {
      await FileSystemService.createDirectory(newPath);
    } catch (e) {
      renameError.value = t.toast.renameError(message: e.toString());
      renameAttempt.value = renameAttempt.value + 1;
      return;
    }
    batch(() {
      pendingCreate.value = null;
      renamingPath.value = null;
      renameError.value = null;
    });
    await refresh();
    final idx = _vf.indexWhere((f) => f.path == newPath);
    if (idx >= 0) {
      batch(() {
        selectedPaths.value = {newPath};
        cursorIndex.value = idx;
        anchorIndex.value = idx;
      });
    }
  }

  void dispose() {
    _searchDebounce?.cancel();
    _searchUiFlush?.cancel();
    _searchHandle?.cancel();
    _watcher.dispose();
  }

  List<FileEntry> get _vf => visibleFiles.value;

  void onSelect(FileSelectionEvent event) {
    final ctrl = AppShortcuts.isControl;
    final shift = AppShortcuts.isShift;

    batch(() {
      if (ctrl && !shift) {
        final paths = Set<String>.from(selectedPaths.value);
        if (paths.contains(event.entry.path)) {
          paths.remove(event.entry.path);
          if (paths.isNotEmpty) {
            final lastSelected = _vf.lastWhere(
              (f) => paths.contains(f.path),
              orElse: () => event.entry,
            );
            anchorIndex.value = _vf.indexOf(lastSelected);
          } else {
            anchorIndex.value = -1;
          }
        } else {
          paths.add(event.entry.path);
          anchorIndex.value = event.index;
        }
        selectedPaths.value = paths;
        cursorIndex.value = event.index;
      } else if (shift && !ctrl) {
        int start;
        if (anchorIndex.value >= 0 &&
            selectedPaths.value.contains(_vf[anchorIndex.value].path)) {
          start = anchorIndex.value;
        } else if (cursorIndex.value >= 0 &&
            selectedPaths.value.contains(_vf[cursorIndex.value].path)) {
          start = cursorIndex.value;
          anchorIndex.value = start;
        } else {
          start = event.index;
          anchorIndex.value = event.index;
        }
        final end = event.index;
        final lo = start < end ? start : end;
        final hi = start < end ? end : start;
        final paths = <String>{};
        for (int i = lo; i <= hi; i++) {
          paths.add(_vf[i].path);
        }
        selectedPaths.value = paths;
        cursorIndex.value = event.index;
      } else {
        selectedPaths.value = {event.entry.path};
        cursorIndex.value = event.index;
        anchorIndex.value = event.index;
      }
    });
  }

  void revealInFolder(String path) {
    final parent = path.substring(0, path.lastIndexOf(Platform.pathSeparator));
    if (parent.isEmpty) return;
    closeSearch();
    navigateTo(parent);
    selectedPaths.value = {path};
  }

  void onOpen(FileEntry entry) {
    if (entry.type == FileItemType.folder) {
      navigateTo(entry.path);
    } else {
      FileSystemService.openWithDefaultApp(entry.path);
    }
  }

  void openSelected() {
    FileEntry? entry;
    if (cursorIndex.value >= 0 && cursorIndex.value < _vf.length) {
      entry = _vf[cursorIndex.value];
    } else if (selectedPaths.value.length == 1) {
      entry = _vf.firstWhere((f) => f.path == selectedPaths.value.first);
    }
    if (entry == null) return;
    if (entry.type == FileItemType.folder) {
      navigateTo(entry.path);
    } else {
      FileSystemService.openWithDefaultApp(entry.path);
    }
  }

  void selectAll() {
    selectedPaths.value = Set<String>.from(_vf.map((f) => f.path));
  }

  void deselectAll() {
    batch(() {
      selectedPaths.value = {};
      cursorIndex.value = -1;
      anchorIndex.value = -1;
    });
  }

  void toggleSelectAndAdvance() {
    batch(() {
      if (cursorIndex.value >= 0 && cursorIndex.value < _vf.length) {
        final path = _vf[cursorIndex.value].path;
        final paths = Set<String>.from(selectedPaths.value);
        if (paths.contains(path)) {
          paths.remove(path);
        } else {
          paths.add(path);
        }
        selectedPaths.value = paths;
      }
      if (cursorIndex.value < _vf.length - 1) {
        cursorIndex.value++;
      }
    });
  }

  void onBackgroundTap() => deselectAll();

  List<FileEntry> get selectedEntries {
    final paths = selectedPaths.value;
    return _vf.where((f) => paths.contains(f.path)).toList();
  }

  void deleteSelected() {
    final entries = selectedEntries;
    if (entries.isEmpty) return;
    final paths = entries.map((e) => e.path).toList();
    batch(() {
      selectedPaths.value = {};
      cursorIndex.value = -1;
      anchorIndex.value = -1;
    });
    operationStore.enqueueDelete(paths);
  }

  void copySelectedPaths() {
    final paths = selectedPaths.value;
    if (paths.isEmpty) return;
    final text = paths.length == 1 ? paths.first : paths.join('\n');
    Clipboard.setData(ClipboardData(text: text));
  }

  void onContextMenu(FileSelectionEvent event) {
    if (!selectedPaths.value.contains(event.entry.path)) {
      batch(() {
        selectedPaths.value = {event.entry.path};
        cursorIndex.value = event.index;
        anchorIndex.value = event.index;
      });
    }
  }

  void copySelected() async {
    if (selectedPaths.value.isEmpty) return;
    final paths = selectedPaths.value.toList();
    batch(() {
      clipboardPaths.value = Set<String>.from(paths);
      clipboardMode.value = ClipboardMode.copy;
    });
    await FileClipboard.writeFiles(paths, isCut: false);
  }

  void cutSelected() async {
    if (selectedPaths.value.isEmpty) return;
    final paths = selectedPaths.value.toList();
    batch(() {
      clipboardPaths.value = Set<String>.from(paths);
      clipboardMode.value = ClipboardMode.cut;
    });
    await FileClipboard.writeFiles(paths, isCut: true);
  }

  void dropFiles(
    List<String> sourcePaths,
    String destination, {
    bool move = false,
  }) {
    final filtered = sourcePaths.where((s) {
      final parent = s.substring(0, s.lastIndexOf(Platform.pathSeparator));
      if (parent == destination) return false;
      if (destination == s) return false;
      if (destination.startsWith('$s${Platform.pathSeparator}')) return false;
      return true;
    }).toList();
    if (filtered.isEmpty) return;
    if (move) {
      operationStore.enqueueMove(filtered, destination);
    } else {
      operationStore.enqueueCopy(filtered, destination);
    }
  }

  void paste() async {
    final internalPaths = Set<String>.from(clipboardPaths.value);
    final internalCut = clipboardMode.value == ClipboardMode.cut;

    final paths = await FileClipboard.readFilePaths();
    if (paths.isEmpty) return;

    final samePaths =
        internalPaths.length == paths.length &&
        internalPaths.containsAll(paths.toSet());

    bool isCut = samePaths && internalCut;
    if (!isCut) isCut = await FileClipboard.isCutOperation();

    final filteredPaths = paths.where((s) {
      final parent = s.substring(0, s.lastIndexOf(Platform.pathSeparator));
      if (parent == currentPath.value) return false;
      if (currentPath.value == s) return false;
      if (currentPath.value.startsWith('$s${Platform.pathSeparator}')) {
        return false;
      }
      return true;
    }).toList();

    if (filteredPaths.isEmpty) {
      if (isCut && samePaths) {
        batch(() {
          clipboardPaths.value = {};
          clipboardMode.value = ClipboardMode.copy;
        });
      }
      return;
    }

    if (isCut) {
      operationStore.enqueueMove(filteredPaths, currentPath.value);
      if (samePaths) {
        batch(() {
          clipboardPaths.value = {};
          clipboardMode.value = null;
        });
      }
    } else {
      operationStore.enqueueCopy(filteredPaths, currentPath.value);
    }
  }

  void moveCursor(int delta) {
    batch(() {
      if (_vf.isEmpty) return;

      final shift = HardwareKeyboard.instance.isShiftPressed;

      if (cursorIndex.value < 0) {
        cursorIndex.value = delta > 0 ? 0 : _vf.length - 1;
        anchorIndex.value = cursorIndex.value;
        selectedPaths.value = {_vf[cursorIndex.value].path};
        return;
      }

      final next = cursorIndex.value + delta;
      if (next < 0 || next >= _vf.length) return;

      if (shift) {
        final lo = next < anchorIndex.value ? next : anchorIndex.value;
        final hi = next < anchorIndex.value ? anchorIndex.value : next;
        final paths = <String>{};
        for (int i = lo; i <= hi; i++) {
          paths.add(_vf[i].path);
        }
        selectedPaths.value = paths;
      } else {
        selectedPaths.value = {_vf[next].path};
      }
      cursorIndex.value = next;
    });
  }
}
