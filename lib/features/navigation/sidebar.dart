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

class _SidebarItem {
  final String label;
  final IconData icon;
  final String path;
  const _SidebarItem(this.label, this.icon, this.path);
}

class Sidebar extends StatefulWidget {
  final NavigationStore store;
  final void Function(String path)? onOpenInNewTab;

  const Sidebar({super.key, required this.store, this.onOpenInNewTab});

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
      child: Watch((context) {
        final currentPath = widget.store.currentPath.value;
        final currentDrives = driveStore.drives.value;

        // Add standard root on Linux if not present dynamically
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
                          widget.store.navigateTo(mountedDrive!.mountPoint!);
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
                              await driveStore.mountWithPassword(drive, pwd);
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
                onUnmount: (isMounted && drive.id != '/' && drive.isRemovable)
                    ? () async {
                        final currentPath = widget.store.currentPath.value;
                        final mountPoint = drive.mountPoint;
                        try {
                          await driveStore.unmount(drive);
                          if (mountPoint != null &&
                              currentPath.startsWith(mountPoint)) {
                            widget.store.navigateTo(PlatformPaths.homePath);
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
    );
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
