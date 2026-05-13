import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart'
    show PhosphorIconsFill, PhosphorIconsRegular, PhosphorIcon;
import 'package:super_drag_and_drop/super_drag_and_drop.dart';
import '../../i18n/strings.g.dart';
import '../../core/models/file_entry.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/theme/app_text_styles.dart';
import '../../utils/drag_drop.dart';
import 'package:path/path.dart' as p;
import '../../utils/format.dart';
import '../operations/drag_hint.dart';
import 'file_icons.dart';
import 'rubber_band_layer.dart';

typedef FileSelectCallback = void Function(FileSelectionEvent event);
typedef FileOpenCallback = void Function(FileEntry entry);
typedef BackgroundTapCallback = void Function();
typedef BackgroundContextMenuCallback = void Function(Offset position);
typedef FileContextMenuCallback =
    void Function(FileSelectionEvent event, Offset position);
typedef FileMenuActionCallback = void Function(String action);
typedef FileDropCallback =
    void Function(List<String> paths, String destination, {bool move});
typedef RenameSubmitCallback = void Function(String newName);
typedef RenameCancelCallback = void Function();
typedef OpenInNewTabCallback = void Function(String path);

const _kDoubleTapMs = 300;
const _kRowHeight = 26.0;
const _kRowGap = 6.0;
const _kItemExtent = _kRowHeight + _kRowGap;

class FileList extends StatefulWidget {
  final List<FileEntry> files;
  final String currentPath;
  final FileSelectCallback onSelect;
  final FileOpenCallback onOpen;
  final BackgroundTapCallback? onBackgroundTap;
  final BackgroundContextMenuCallback? onBackgroundContextMenu;
  final FileContextMenuCallback? onContextMenu;
  final FileMenuActionCallback? onMenuAction;
  final FileDropCallback? onDropFiles;
  final Set<String> selectedPaths;
  final Set<String> cutPaths;
  final String? renamingPath;
  final int renameAttempt;
  final RenameSubmitCallback? onRenameSubmit;
  final RenameCancelCallback? onRenameCancel;
  final bool recursiveResults;
  final VoidCallback? onCloseSearch;
  final OpenInNewTabCallback? onOpenInNewTab;
  final RubberBandSelectCallback? onRectSelect;

  const FileList({
    super.key,
    required this.files,
    required this.currentPath,
    required this.onSelect,
    required this.onOpen,
    this.onBackgroundTap,
    this.onBackgroundContextMenu,
    this.onContextMenu,
    this.onMenuAction,
    this.onDropFiles,
    this.selectedPaths = const {},
    this.cutPaths = const {},
    this.renamingPath,
    this.renameAttempt = 0,
    this.onRenameSubmit,
    this.onRenameCancel,
    this.recursiveResults = false,
    this.onCloseSearch,
    this.onOpenInNewTab,
    this.onRectSelect,
  });

  @override
  State<FileList> createState() => _FileListState();
}

class _FileListState extends State<FileList> {
  final _scrollController = ScrollController();
  bool _isDragOver = false;
  String? _hoveredFolderPath;

  String? _relativeParent(String entryPath, String currentPath) {
    final rel = p.relative(p.dirname(entryPath), from: currentPath);
    if (rel == '.') return null;
    return rel;
  }

  int _rowAt(Offset localPosition) {
    if (localPosition.dy < 0) return -1;
    final adjustedY = localPosition.dy + _scrollController.offset;
    final index = (adjustedY / _kItemExtent).floor();
    if (index < 0 || index >= widget.files.length) return -1;

    final relativeY = adjustedY % _kItemExtent;
    if (relativeY >= _kRowHeight) return -1;

    return index;
  }

  void _updateHover(Offset localPosition) {
    final index = _rowAt(localPosition);
    String? folder;
    if (index >= 0) {
      final entry = widget.files[index];
      if (entry.type == FileItemType.folder) folder = entry.path;
    }
    if (folder != _hoveredFolderPath || !_isDragOver) {
      setState(() {
        _isDragOver = true;
        _hoveredFolderPath = folder;
      });
    }
  }

  void _clearDrag() {
    if (_isDragOver || _hoveredFolderPath != null) {
      setState(() {
        _isDragOver = false;
        _hoveredFolderPath = null;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.files.isEmpty) {
      return GestureDetector(
        onTap: widget.onBackgroundTap,
        onSecondaryTapUp: widget.onBackgroundContextMenu != null
            ? (d) => widget.onBackgroundContextMenu!(d.globalPosition)
            : null,
        behavior: HitTestBehavior.opaque,
        child: _EmptyState(
          isSearching: widget.recursiveResults,
          onCloseSearch: widget.onCloseSearch,
        ),
      );
    }

    return Column(
      children: [
        _ListHeader(recursive: widget.recursiveResults),
        Divider(height: 1, thickness: 1, color: AppColors.bgDivider),
        Expanded(
          child: RubberBandLayer(
            scrollController: _scrollController,
            itemCount: widget.files.length,
            itemExtent: _kItemExtent,
            rowHeight: _kRowHeight,
            pathAt: (i) => widget.files[i].path,
            rowAt: _rowAt,
            onSelectionChanged: widget.onRectSelect,
            onBackgroundTap: widget.onBackgroundTap,
            child: DropRegion(
              formats: [Formats.fileUri, formatLocalFile],
              hitTestBehavior: HitTestBehavior.opaque,
              onDropOver: (event) {
                _updateHover(event.position.local);
                return DragHintController.instance.mode.value == DragMode.move
                    ? DropOperation.move
                    : DropOperation.copy;
              },
              onDropLeave: (_) => _clearDrag(),
              onDropEnded: (_) {
                _clearDrag();
              },
              onPerformDrop: (event) async {
                final pos = event.position.local;
                final index = _rowAt(pos);
                String? target;
                if (index >= 0 &&
                    widget.files[index].type == FileItemType.folder) {
                  target = widget.files[index].path;
                }
                final paths = await pathsFromSession(event.session);
                final move =
                    DragHintController.instance.mode.value == DragMode.move;
                if (paths.isNotEmpty) {
                  widget.onDropFiles?.call(
                    paths,
                    target ?? widget.currentPath,
                    move: move,
                  );
                }
                _clearDrag();
              },
              child: Stack(
                children: [
                  GestureDetector(
                    onSecondaryTapUp: (d) {
                      final index = _rowAt(d.localPosition);
                      if (index < 0) {
                        widget.onBackgroundTap?.call();
                        widget.onBackgroundContextMenu?.call(d.globalPosition);
                      }
                    },
                    behavior: HitTestBehavior.translucent,
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.zero,
                      itemCount: widget.files.length,
                      itemExtent: _kItemExtent,
                      itemBuilder: (context, i) => Padding(
                        padding: const EdgeInsets.only(bottom: _kRowGap),
                        child: _ListRow(
                          entry: widget.files[i],
                          index: i,
                          selected: widget.selectedPaths.contains(
                            widget.files[i].path,
                          ),
                          selectedPaths: widget.selectedPaths,
                          isCut: widget.cutPaths.contains(widget.files[i].path),
                          isDraggingSelected: widget.selectedPaths.isNotEmpty,
                          isFolderDragOver:
                              _hoveredFolderPath == widget.files[i].path,
                          isRenaming:
                              widget.renamingPath == widget.files[i].path,
                          renameAttempt: widget.renameAttempt,
                          onRenameSubmit: widget.onRenameSubmit,
                          onRenameCancel: widget.onRenameCancel,
                          onSelect: widget.onSelect,
                          onOpen: widget.onOpen,
                          onContextMenu: widget.onContextMenu,
                          onMenuAction: widget.onMenuAction,
                          recursive: widget.recursiveResults,
                          location: widget.recursiveResults
                              ? _relativeParent(
                                  widget.files[i].path,
                                  widget.currentPath,
                                )
                              : null,
                          onOpenInNewTab: widget.onOpenInNewTab,
                        ),
                      ),
                    ),
                  ),
                  if (_isDragOver)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.accent.withValues(alpha: 0.4),
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ListHeader extends StatelessWidget {
  final bool recursive;
  const _ListHeader({this.recursive = false});

  @override
  Widget build(BuildContext context) {
    final headerStyle = context.txt.fieldLabel;
    return Container(
      height: 24,
      padding: const EdgeInsets.only(left: 12, right: 16),
      decoration: const BoxDecoration(color: AppColors.bg),
      child: Row(
        children: [
          const SizedBox(width: 22),
          Expanded(
            flex: 3,
            child: Text(t.fileView.columns.name, style: headerStyle),
          ),
          if (recursive) ...[
            Expanded(
              flex: 4,
              child: Text(t.fileView.columns.location, style: headerStyle),
            ),
          ] else ...[
            SizedBox(
              width: 80,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(t.fileView.columns.size, style: headerStyle),
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 170,
              child: Text(t.fileView.columns.dateModified, style: headerStyle),
            ),
          ],
        ],
      ),
    );
  }
}

class _ListRow extends StatefulWidget {
  final FileEntry entry;
  final int index;
  final bool selected;
  final Set<String> selectedPaths;
  final bool isCut;
  final bool isDraggingSelected;
  final bool isFolderDragOver;
  final bool isRenaming;
  final int renameAttempt;
  final RenameSubmitCallback? onRenameSubmit;
  final RenameCancelCallback? onRenameCancel;
  final FileSelectCallback onSelect;
  final FileOpenCallback onOpen;
  final FileContextMenuCallback? onContextMenu;
  final FileMenuActionCallback? onMenuAction;
  final bool recursive;
  final String? location;
  final OpenInNewTabCallback? onOpenInNewTab;

  const _ListRow({
    required this.entry,
    required this.index,
    required this.selected,
    required this.selectedPaths,
    this.isCut = false,
    this.isDraggingSelected = false,
    this.isFolderDragOver = false,
    this.isRenaming = false,
    this.renameAttempt = 0,
    this.onRenameSubmit,
    this.onRenameCancel,
    required this.onSelect,
    required this.onOpen,
    this.onContextMenu,
    this.onMenuAction,
    this.recursive = false,
    this.location,
    this.onOpenInNewTab,
  });

  @override
  State<_ListRow> createState() => _ListRowState();
}

class _ListRowState extends State<_ListRow> {
  bool _hovered = false;
  bool _dragging = false;
  DateTime? _lastTap;
  TextEditingController? _renameController;
  FocusNode? _renameFocusNode;
  bool _renameCommitted = false;

  @override
  void initState() {
    super.initState();
    if (widget.isRenaming) _initRenameFields();
  }

  @override
  void didUpdateWidget(covariant _ListRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRenaming && !oldWidget.isRenaming) {
      _initRenameFields();
    } else if (!widget.isRenaming && oldWidget.isRenaming) {
      _disposeRenameFields();
    } else if (widget.isRenaming &&
        widget.renameAttempt != oldWidget.renameAttempt) {
      _renameCommitted = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _renameFocusNode == null || _renameController == null) {
          return;
        }
        _renameFocusNode!.requestFocus();
        _renameController!.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _renameController!.text.length,
        );
      });
    }
  }

  void _initRenameFields() {
    _renameCommitted = false;
    final name = widget.entry.name;
    String initialText;
    int selectionEnd;
    if (widget.entry.type == FileItemType.file) {
      final dotIndex = name.lastIndexOf('.');
      if (dotIndex > 0) {
        initialText = name;
        selectionEnd = dotIndex;
      } else {
        initialText = name;
        selectionEnd = name.length;
      }
    } else {
      initialText = name;
      selectionEnd = name.length;
    }
    _renameController = TextEditingController(text: initialText);
    _renameController!.selection = TextSelection(
      baseOffset: 0,
      extentOffset: selectionEnd,
    );
    _renameFocusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _renameFocusNode != null) {
        _renameFocusNode!.requestFocus();
      }
    });
  }

  void _disposeRenameFields() {
    _renameController?.dispose();
    _renameController = null;
    _renameFocusNode?.dispose();
    _renameFocusNode = null;
  }

  @override
  void dispose() {
    _disposeRenameFields();
    super.dispose();
  }

  void _commitRename() {
    if (_renameCommitted) return;
    _renameCommitted = true;
    final newName = _renameController?.text ?? '';
    widget.onRenameSubmit?.call(newName);
  }

  void _cancelRename() {
    if (_renameCommitted) return;
    _renameCommitted = true;
    widget.onRenameCancel?.call();
  }

  Color get _bg {
    if (widget.isFolderDragOver) {
      return AppColors.accent.withValues(alpha: 0.12);
    }
    if (_dragging) return AppColors.accent.withValues(alpha: 0.08);
    if (widget.selected) return AppColors.bgSelectedMuted;
    if (_hovered) return AppColors.bgHover;
    return Colors.transparent;
  }

  BoxBorder? get _border {
    if (widget.isFolderDragOver) {
      return Border.all(color: AppColors.accent.withValues(alpha: 0.4));
    }
    if (widget.selected) {
      return Border(left: BorderSide(color: AppColors.accent, width: 2));
    }
    return null;
  }

  void _handleTap() {
    final now = DateTime.now();
    if (_lastTap != null &&
        now.difference(_lastTap!).inMilliseconds < _kDoubleTapMs) {
      _lastTap = null;
      widget.onOpen(widget.entry);
      return;
    }
    _lastTap = now;
    widget.onSelect(
      FileSelectionEvent(entry: widget.entry, index: widget.index),
    );
  }

  void _handleSecondaryTap(TapUpDetails details) {
    widget.onContextMenu?.call(
      FileSelectionEvent(entry: widget.entry, index: widget.index),
      details.globalPosition,
    );
  }

  Widget _buildDragImage(BuildContext context, Widget child) {
    final dragCount = widget.selected ? widget.selectedPaths.length : 1;

    final e = widget.entry;
    final isFolder = e.type == FileItemType.folder;

    final visualRow = Container(
      width: 260,
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.bgSidebar,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.bgDivider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          PhosphorIcon(
            isFolder ? PhosphorIconsFill.folder : fileIcon(e.extension),
            size: 20,
            color: isFolder
                ? AppColors.folderColor
                : fileIconColor(e.extension),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              dragCount > 1 ? t.fileView.movingItems(count: dragCount) : e.name,
              overflow: TextOverflow.ellipsis,
              style: context.txt.dialogTitle.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );

    return visualRow;
  }

  Future<DragItem?> _provideDragItem(DragItemRequest request) async {
    List<String> pathsToDrag;

    if (!widget.selected) {
      widget.onSelect(
        FileSelectionEvent(entry: widget.entry, index: widget.index),
      );
      pathsToDrag = [widget.entry.path];
    } else {
      pathsToDrag = widget.selectedPaths.toList();
    }

    final item = DragItem(localData: {'paths': pathsToDrag});
    item.add(formatLocalFile(pathsToDrag.join('\n')));

    for (final path in pathsToDrag) {
      item.add(Formats.fileUri(Uri.file(path)));
    }

    final initialMode = HardwareKeyboard.instance.isAltPressed
        ? DragMode.move
        : DragMode.copy;

    void updateDragging() {
      final isDragging = request.session.dragging.value;
      if (mounted) {
        setState(() => _dragging = isDragging);
      }
      if (isDragging) {
        DragHintController.instance.mode.value = initialMode;
      }
    }

    request.session.dragging.addListener(updateDragging);
    updateDragging();

    return item;
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    final isFolder = e.type == FileItemType.folder;
    final opacity = widget.isCut ? 0.4 : (_dragging ? 0.4 : 1.0);

    if (widget.isRenaming) {
      return MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Container(
          height: _kRowHeight,
          padding: const EdgeInsets.only(left: 12, right: 16),
          decoration: BoxDecoration(color: _bg, border: _border),
          child: Opacity(
            opacity: opacity,
            child: Row(
              children: [
                PhosphorIcon(
                  isFolder ? PhosphorIconsFill.folder : fileIcon(e.extension),
                  size: 16,
                  color: isFolder
                      ? AppColors.folderColor
                      : fileIconColor(e.extension),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 3,
                  child: CallbackShortcuts(
                    bindings: {
                      const SingleActivator(LogicalKeyboardKey.escape):
                          _cancelRename,
                    },
                    child: TextField(
                      controller: _renameController,
                      focusNode: _renameFocusNode,
                      autofocus: true,
                      style: context.txt.bodyEmphasis,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 3,
                        ),
                        filled: true,
                        fillColor: AppColors.bgInput,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(3),
                          borderSide: BorderSide(
                            color: AppColors.accent,
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(3),
                          borderSide: BorderSide(
                            color: AppColors.bgDivider,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(3),
                          borderSide: BorderSide(
                            color: AppColors.accent,
                            width: 1,
                          ),
                        ),
                      ),
                      onSubmitted: (_) => _commitRename(),
                      onTapOutside: (_) => _commitRename(),
                    ),
                  ),
                ),
                if (widget.recursive) ...[
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        widget.location ?? '',
                        overflow: TextOverflow.ellipsis,
                        style: context.txt.muted,
                      ),
                    ),
                  ),
                ] else ...[
                  SizedBox(
                    width: 80,
                    child: Text(
                      isFolder ? '--' : formatBytes(e.size),
                      textAlign: TextAlign.right,
                      style: context.txt.muted,
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 170,
                    child: Text(
                      _formatDate(e.modified),
                      style: context.txt.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    final row = MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: _handleTap,
        onSecondaryTapUp: _handleSecondaryTap,
        onTertiaryTapUp: (_) {
          if (widget.entry.type == FileItemType.folder) {
            widget.onOpenInNewTab?.call(widget.entry.path);
          }
        },
        child: Container(
          height: _kRowHeight,
          padding: const EdgeInsets.only(left: 12, right: 16),
          decoration: BoxDecoration(
            color: _bg,
            borderRadius: widget.isFolderDragOver
                ? BorderRadius.circular(4)
                : null,
            border: _border,
          ),
          child: Opacity(
            opacity: opacity,
            child: Row(
              children: [
                PhosphorIcon(
                  isFolder ? PhosphorIconsFill.folder : fileIcon(e.extension),
                  size: 16,
                  color: isFolder
                      ? AppColors.folderColor
                      : fileIconColor(e.extension),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 3,
                  child: Text(
                    e.name,
                    overflow: TextOverflow.ellipsis,
                    style: context.txt.body.copyWith(
                      color: widget.selected
                          ? AppColors.fg
                          : AppColors.fg.withValues(alpha: 0.9),
                      fontWeight: widget.selected
                          ? FontWeight.w500
                          : FontWeight.normal,
                    ),
                  ),
                ),
                if (widget.recursive) ...[
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        widget.location ?? '',
                        overflow: TextOverflow.ellipsis,
                        style: context.txt.muted,
                      ),
                    ),
                  ),
                ] else ...[
                  SizedBox(
                    width: 80,
                    child: Text(
                      isFolder ? '--' : formatBytes(e.size),
                      textAlign: TextAlign.right,
                      style: context.txt.muted,
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 170,
                    child: Text(
                      _formatDate(e.modified),
                      style: context.txt.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    return DragItemWidget(
      dragItemProvider: _provideDragItem,
      allowedOperations: () => [DropOperation.copy, DropOperation.move],
      canAddItemToExistingSession: true,
      dragBuilder: _buildDragImage,
      child: DraggableWidget(child: row),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isSearching;
  final VoidCallback? onCloseSearch;

  const _EmptyState({this.isSearching = false, this.onCloseSearch});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: null,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(
              PhosphorIconsRegular.folderOpen,
              size: 48,
              color: AppColors.fgSubtle,
            ),
            const SizedBox(height: 12),
            if (isSearching) ...[
              Text(
                t.search.noMatches,
                style: context.txt.dialogTitle.copyWith(
                  color: AppColors.fgMuted,
                ),
              ),
              const SizedBox(height: 8),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: onCloseSearch,
                  child: Text(
                    t.search.clear,
                    style: context.txt.body.copyWith(
                      color: AppColors.accent,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ] else
              Text(
                t.fileView.empty,
                style: context.txt.dialogTitle.copyWith(
                  color: AppColors.fgMuted,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime d) {
  return '${d.year}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')} '
      '${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}';
}
