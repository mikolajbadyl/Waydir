import 'dart:io';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:signals/signals_flutter.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';
import 'navigation_store.dart';
import '../drives/drive_store.dart';
import '../drives/drive_model.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/theme/app_text_styles.dart';
import '../../ui/dialogs/password_dialog.dart';
import '../../core/platform/platform_paths.dart';
import '../../i18n/strings.g.dart';
import '../../utils/drag_drop.dart';
import '../operations/drag_hint.dart';
import '../operations/operation_store.dart';
import '../operations/operations_panel.dart';
import '../../core/models/file_operation.dart';

class _SidebarItem {
  final String label;
  final IconData icon;
  final String path;
  const _SidebarItem(this.label, this.icon, this.path);
}

class Sidebar extends StatefulWidget {
  final NavigationStore store;
  final OperationStore operationStore;
  final void Function(String path)? onOpenInNewTab;

  const Sidebar({
    super.key,
    required this.store,
    required this.operationStore,
    this.onOpenInNewTab,
  });

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  late final List<_SidebarItem> _favorites;

  @override
  void initState() {
    super.initState();
    final h = PlatformPaths.homePath;
    _favorites = [
      _SidebarItem(t.sidebar.home, PhosphorIconsRegular.house, h),
      _SidebarItem(
        t.sidebar.desktop,
        PhosphorIconsRegular.desktop,
        PlatformPaths.desktopPath,
      ),
      _SidebarItem(
        t.sidebar.documents,
        PhosphorIconsRegular.notebook,
        PlatformPaths.documentsPath,
      ),
      _SidebarItem(
        t.sidebar.downloads,
        PhosphorIconsRegular.downloadSimple,
        PlatformPaths.downloadsPath,
      ),
      _SidebarItem(
        t.sidebar.pictures,
        PhosphorIconsRegular.image,
        PlatformPaths.picturesPath,
      ),
      _SidebarItem(
        t.sidebar.music,
        PhosphorIconsRegular.musicNote,
        PlatformPaths.musicPath,
      ),
      _SidebarItem(
        t.sidebar.videos,
        PhosphorIconsRegular.videoCamera,
        PlatformPaths.videosPath,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgSidebar,
      child: Column(
        children: [
          Expanded(
            child: Watch((context) {
              final currentPath = widget.store.currentPath.value;
              final currentDrives = driveStore.drives.value;

              final devices = <Drive>[...currentDrives];
              final isUnix = PlatformPaths.isLinux || PlatformPaths.isMacOS;
              if (isUnix && !devices.any((d) => d.mountPoint == '/')) {
                devices.insert(
                  0,
                  Drive(
                    id: '/',
                    label: t.sidebar.root,
                    isRemovable: false,
                    mountPoint: '/',
                  ),
                );
              }

              return ListView(
                padding: EdgeInsets.zero,
                children: [
                  _SectionHeader(title: t.sidebar.favorites),
                  ..._favorites.map(
                    (item) => _ItemRow(
                      item: item,
                      isSelected: currentPath == item.path,
                      onTap: widget.store.navigateTo,
                      onMiddleTap: widget.onOpenInNewTab != null
                          ? () => widget.onOpenInNewTab!(item.path)
                          : null,
                      onDropFiles: (paths, {bool move = false}) =>
                          widget.store.dropFiles(paths, item.path, move: move),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _SectionHeader(title: t.sidebar.devices),
                  ...devices.map((drive) {
                    final path = drive.mountPoint ?? drive.id;
                    final isSelected = currentPath == path;
                    final isMounted = drive.isMounted;

                    return _ItemRow(
                      item: _SidebarItem(
                        drive.label,
                        drive.isRemovable
                            ? PhosphorIconsRegular.usb
                            : PhosphorIconsRegular.hardDrive,
                        path,
                      ),
                      isSelected: isSelected,
                      isMounted: isMounted,
                      onTap: (p) async {
                        if (isMounted) {
                          widget.store.navigateTo(p);
                        } else {
                          try {
                            await driveStore.mount(drive);
                            Future.microtask(() {
                              final mountedDrive = driveStore.drives.value
                                  .where((d) => d.id == drive.id)
                                  .firstOrNull;
                              if (mountedDrive?.isMounted == true) {
                                widget.store.navigateTo(
                                  mountedDrive!.mountPoint!,
                                );
                              }
                            });
                          } catch (e) {
                            final error = e.toString().toLowerCase();
                            if (error.contains('not authorized') ||
                                error.contains('polkit') ||
                                error.contains('authenticate')) {
                              if (context.mounted) {
                                final pwd = await showPasswordDialog(
                                  context,
                                  title: 'Mount ${drive.label}',
                                );
                                if (pwd != null) {
                                  try {
                                    await driveStore.mountWithPassword(
                                      drive,
                                      pwd,
                                    );
                                    Future.microtask(() {
                                      final mountedDrive = driveStore
                                          .drives
                                          .value
                                          .where((d) => d.id == drive.id)
                                          .firstOrNull;
                                      if (mountedDrive?.isMounted == true) {
                                        widget.store.navigateTo(
                                          mountedDrive!.mountPoint!,
                                        );
                                      }
                                    });
                                  } catch (_) {}
                                }
                              }
                            }
                          }
                        }
                      },
                      onMiddleTap: widget.onOpenInNewTab != null && isMounted
                          ? () => widget.onOpenInNewTab!(path)
                          : null,
                      onDropFiles: (paths, {bool move = false}) {
                        if (isMounted) {
                          widget.store.dropFiles(paths, path, move: move);
                        }
                      },
                      onUnmount:
                          (isMounted && drive.id != '/' && drive.isRemovable)
                          ? () async {
                              final currentPath =
                                  widget.store.currentPath.value;
                              final mountPoint = drive.mountPoint;
                              try {
                                await driveStore.unmount(drive);
                                if (mountPoint != null &&
                                    currentPath.startsWith(mountPoint)) {
                                  widget.store.navigateTo(
                                    PlatformPaths.homePath,
                                  );
                                }
                              } catch (_) {}
                            }
                          : null,
                    );
                  }),
                  const SizedBox(height: 8),
                ],
              );
            }),
          ),
          _SidebarOperationsButton(operationStore: widget.operationStore),
        ],
      ),
    );
  }
}

class _SidebarOperationsButton extends StatefulWidget {
  final OperationStore operationStore;

  const _SidebarOperationsButton({required this.operationStore});

  @override
  State<_SidebarOperationsButton> createState() =>
      _SidebarOperationsButtonState();
}

class _SidebarOperationsButtonState extends State<_SidebarOperationsButton> {
  bool _hovered = false;

  void _openPanel() {
    final box = context.findRenderObject() as RenderBox;
    final offset = box.localToGlobal(Offset(box.size.width + 6, 0));
    showOperationsPanel(
      context: context,
      position: offset,
      operationStore: widget.operationStore,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final tasks = widget.operationStore.tasks.value;
      final active = tasks.where(_isActiveTask).firstOrNull;
      if (active == null) return const SizedBox.shrink();

      final activeCount = widget.operationStore.activeCount.value;
      final progress = active.progress.clamp(0.0, 1.0).toDouble();
      final progressText = '${(progress * 100).round()}%';

      return Container(
        padding: const EdgeInsets.fromLTRB(6, 7, 6, 7),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.bgDivider)),
        ),
        child: Tooltip(
          message: t.toolbar.operations,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() => _hovered = false),
            child: GestureDetector(
              onTap: _openPanel,
              behavior: HitTestBehavior.opaque,
              child: Container(
                constraints: const BoxConstraints(minHeight: 44),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(
                    alpha: _hovered ? 0.18 : 0.11,
                  ),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.42),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        PhosphorIcon(
                          _operationIcon(active),
                          size: 15,
                          color: AppColors.fgAccent,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            TaskLabel.title(active),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.txt.rowEmphasis.copyWith(
                              color: AppColors.fg,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          activeCount > 1
                              ? '$progressText · $activeCount'
                              : progressText,
                          style: context.txt.caption.copyWith(
                            color: AppColors.fgAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: active.totalFiles > 0 ? progress : null,
                        minHeight: 3,
                        backgroundColor: AppColors.bgInput,
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  static bool _isActiveTask(FileTask task) {
    return task.status == TaskStatus.queued ||
        task.status == TaskStatus.preparing ||
        task.status == TaskStatus.waitingConflicts ||
        task.status == TaskStatus.running ||
        task.status == TaskStatus.cancelling;
  }

  static IconData _operationIcon(FileTask? task) {
    if (task == null) return PhosphorIconsRegular.clockClockwise;
    if (task.status == TaskStatus.waitingConflicts) {
      return PhosphorIconsRegular.warning;
    }
    return switch (task.type) {
      TaskType.copy => PhosphorIconsRegular.copy,
      TaskType.move => PhosphorIconsRegular.arrowRight,
      TaskType.delete => PhosphorIconsRegular.trash,
    };
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}

class _ItemRow extends StatefulWidget {
  final _SidebarItem item;
  final bool isSelected;
  final bool isMounted;
  final ValueChanged<String> onTap;
  final VoidCallback? onMiddleTap;
  final void Function(List<String> paths, {bool move}) onDropFiles;
  final VoidCallback? onUnmount;

  const _ItemRow({
    required this.item,
    required this.isSelected,
    this.isMounted = true,
    required this.onTap,
    this.onMiddleTap,
    required this.onDropFiles,
    this.onUnmount,
  });

  @override
  State<_ItemRow> createState() => _ItemRowState();
}

class _ItemRowState extends State<_ItemRow> {
  bool _hovered = false;
  bool _dragOver = false;

  @override
  Widget build(BuildContext context) {
    Color bg;
    if (_dragOver) {
      bg = AppColors.accent.withValues(alpha: 0.12);
    } else if (widget.isSelected) {
      bg = AppColors.bgSelectedMuted;
    } else if (_hovered) {
      bg = AppColors.bgHover;
    } else {
      bg = Colors.transparent;
    }

    return DropRegion(
      formats: [Formats.fileUri, formatLocalFile],
      hitTestBehavior: HitTestBehavior.opaque,
      onDropOver: (event) {
        if (!_dragOver) setState(() => _dragOver = true);
        return DragHintController.instance.mode.value == DragMode.move
            ? DropOperation.move
            : DropOperation.copy;
      },
      onDropLeave: (_) {
        if (_dragOver) setState(() => _dragOver = false);
      },
      onDropEnded: (_) {
        if (_dragOver) setState(() => _dragOver = false);
      },
      onPerformDrop: (event) async {
        final paths = await pathsFromSession(event.session);
        final move = DragHintController.instance.mode.value == DragMode.move;
        if (paths.isNotEmpty) widget.onDropFiles(paths, move: move);
        if (_dragOver) setState(() => _dragOver = false);
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: () {
            if (!widget.isMounted || Directory(widget.item.path).existsSync()) {
              widget.onTap(widget.item.path);
            }
          },
          onTertiaryTapUp: (_) {
            if (widget.isMounted && Directory(widget.item.path).existsSync()) {
              widget.onMiddleTap?.call();
            }
          },
          child: Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(4),
              border: _dragOver
                  ? Border.all(color: AppColors.accent.withValues(alpha: 0.4))
                  : null,
            ),
            child: Row(
              children: [
                PhosphorIcon(
                  widget.item.icon,
                  size: 16,
                  color: widget.isSelected
                      ? AppColors.fgAccent
                      : AppColors.fgMuted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.item.label,
                    overflow: TextOverflow.ellipsis,
                    style: context.txt.body.copyWith(
                      color: widget.isSelected
                          ? AppColors.fg
                          : (widget.isMounted
                                ? AppColors.fg.withValues(alpha: 0.85)
                                : AppColors.fgMuted),
                      fontWeight: widget.isSelected
                          ? FontWeight.w500
                          : FontWeight.normal,
                    ),
                  ),
                ),
                if (widget.onUnmount != null)
                  IconButton(
                    icon: const PhosphorIcon(
                      PhosphorIconsRegular.eject,
                      size: 14,
                      color: AppColors.fgMuted,
                    ),
                    onPressed: widget.onUnmount,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                    splashRadius: 12,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
