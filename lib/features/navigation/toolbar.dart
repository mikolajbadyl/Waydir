import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:signals/signals_flutter.dart';
import 'navigation_store.dart';
import '../../ui/overlays/notification_store.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/theme/app_text_styles.dart';
import '../../i18n/strings.g.dart';
import '../../ui/overlays/context_menu.dart';
import '../operations/operations_panel.dart';
import '../../ui/overlays/notifications_panel.dart';
import '../panes/shell_store.dart';

class Toolbar extends StatelessWidget {
  final NavigationStore store;
  final NotificationStore notificationStore;
  final ShellStore? shellStore;

  const Toolbar({
    super.key,
    required this.store,
    required this.notificationStore,
    this.shellStore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: const BoxDecoration(
        color: AppColors.bgToolbar,
        border: Border(bottom: BorderSide(color: AppColors.bgDivider)),
      ),
      child: Row(
        children: [
          Watch(
            (context) => _ToolBtn(
              PhosphorIconsRegular.arrowLeft,
              store.goBack,
              store.canGoBack.value,
              t.toolbar.back,
            ),
          ),
          Watch(
            (context) => _ToolBtn(
              PhosphorIconsRegular.arrowRight,
              store.goForward,
              store.canGoForward.value,
              t.toolbar.forward,
            ),
          ),
          _ToolBtn(
            PhosphorIconsRegular.arrowUp,
            store.goUp,
            true,
            t.toolbar.up,
          ),
          Container(
            width: 1,
            height: 16,
            color: AppColors.bgDivider,
            margin: const EdgeInsets.symmetric(horizontal: 4),
          ),
          _ToolBtn(
            PhosphorIconsRegular.arrowClockwise,
            store.refresh,
            true,
            t.toolbar.refresh,
          ),
          const SizedBox(width: 6),
          Expanded(child: _PathBar(store: store)),
          const SizedBox(width: 6),
          Watch(
            (context) => _ToolBtn(
              PhosphorIconsRegular.magnifyingGlass,
              () => store.searchActive.value
                  ? store.closeSearch()
                  : store.openSearch(),
              true,
              t.toolbar.search,
            ),
          ),
          _NewFolderButton(store: store),
          _OperationsButton(store: store),
          _ViewOptionsButton(store: store, shellStore: shellStore),
          _NotificationsButton(notificationStore: notificationStore),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _ToolBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;
  final String tooltip;

  const _ToolBtn(this.icon, this.onTap, this.enabled, this.tooltip);

  @override
  State<_ToolBtn> createState() => _ToolBtnState();
}

class _ToolBtnState extends State<_ToolBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.enabled ? widget.onTap : null,
          child: Container(
            width: 30,
            height: 30,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: _hovered && widget.enabled
                  ? AppColors.bgHover
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: PhosphorIcon(
              widget.icon,
              size: 16,
              color: widget.enabled
                  ? (_hovered ? AppColors.fg : AppColors.fgMuted)
                  : AppColors.fgSubtle,
            ),
          ),
        ),
      ),
    );
  }
}

class _PathBar extends StatefulWidget {
  final NavigationStore store;

  const _PathBar({required this.store});

  @override
  State<_PathBar> createState() => _PathBarState();
}

class _PathBarState extends State<_PathBar> {
  bool _editing = false;
  late TextEditingController _controller;
  final _focusNode = FocusNode();
  final _editorKeyFocusNode = FocusNode();
  void Function()? _disposePathListener;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.store.currentPath.value);
    _disposePathListener = effect(() {
      final path = widget.store.currentPath.value;
      if (!_editing && _controller.text != path) {
        _controller.text = path;
      }
    });
  }

  @override
  void dispose() {
    _disposePathListener?.call();
    _controller.dispose();
    _focusNode.dispose();
    _editorKeyFocusNode.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() {
      _editing = true;
      _controller.text = widget.store.currentPath.value;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    });
  }

  void _submit() {
    final text = _controller.text.trim();
    setState(() => _editing = false);
    if (text.isNotEmpty && text != widget.store.currentPath.value) {
      widget.store.navigateTo(text);
    }
  }

  void _cancel() {
    setState(() => _editing = false);
    _controller.text = widget.store.currentPath.value;
  }

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final path = widget.store.currentPath.value;
      return GestureDetector(
        onTap: _editing ? null : _startEditing,
        child: Container(
          height: 26,
          decoration: BoxDecoration(
            color: AppColors.bgInput,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: _editing ? AppColors.accent : AppColors.borderColor,
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: _editing ? 4 : 8),
          child: _editing ? _buildEditor() : _buildBreadcrumbs(path),
        ),
      );
    });
  }

  Widget _buildEditor() {
    return Row(
      children: [
        Expanded(
          child: KeyboardListener(
            focusNode: _editorKeyFocusNode,
            onKeyEvent: (event) {
              if (event is KeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.escape) {
                _cancel();
              }
            },
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              onSubmitted: (_) => _submit(),
              style: context.txt.body,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 4,
                ),
                border: InputBorder.none,
              ),
              cursorColor: AppColors.accent,
              cursorHeight: 14,
            ),
          ),
        ),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: _cancel,
            child: Padding(
              padding: const EdgeInsets.only(left: 2, right: 2),
              child: PhosphorIcon(
                PhosphorIconsRegular.x,
                size: 14,
                color: AppColors.fgMuted,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBreadcrumbs(String path) {
    final segments = path
        .split(Platform.pathSeparator)
        .where((s) => s.isNotEmpty)
        .toList();
    final hasRoot = Platform.isLinux || Platform.isMacOS;

    return LayoutBuilder(
      builder: (context, constraints) {
        final txt = context.txt;
        final regular = txt.body;
        final bold = txt.bodyEmphasis;
        const segPadding = 6.0;
        const caretWidth = 16.0;
        const ellipsisWidth = 14.0 + segPadding;

        double measure(String text, TextStyle style) {
          final tp = TextPainter(
            text: TextSpan(text: text, style: style),
            textDirection: TextDirection.ltr,
            maxLines: 1,
          )..layout();
          return tp.width;
        }

        double segW(String s, {bool last = false}) =>
            measure(s, last ? bold : regular) + segPadding;

        final maxW = constraints.maxWidth;
        final rootW = hasRoot ? segW('/') : 0.0;

        final widths = <double>[];
        double total = rootW;
        for (int i = 0; i < segments.length; i++) {
          final w =
              caretWidth + segW(segments[i], last: i == segments.length - 1);
          widths.add(w);
          total += w;
        }

        if (total <= maxW) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasRoot)
                _BreadcrumbSegment(
                  label: '/',
                  onTap: () => widget.store.navigateTo('/'),
                ),
              for (int i = 0; i < segments.length; i++)
                ..._segmentRow(
                  segments,
                  i,
                  isLast: i == segments.length - 1,
                  flexibleLast: false,
                ),
            ],
          );
        }

        final reserved = rootW + caretWidth + ellipsisWidth;
        double remaining = maxW - reserved;
        final shown = <int>[];
        for (int i = segments.length - 1; i >= 0; i--) {
          if (shown.isEmpty || widths[i] <= remaining) {
            shown.insert(0, i);
            remaining -= widths[i];
            if (remaining <= 0 && shown.isNotEmpty) break;
          } else {
            break;
          }
        }
        final hidden = List.generate(shown.first, (i) => i);

        return Row(
          children: [
            if (hasRoot)
              _BreadcrumbSegment(
                label: '/',
                onTap: () => widget.store.navigateTo('/'),
              ),
            _caretIcon(),
            _EllipsisMenu(
              hiddenIndices: hidden,
              allSegments: segments,
              store: widget.store,
            ),
            for (int k = 0; k < shown.length; k++)
              ...() {
                final i = shown[k];
                final isLast = i == segments.length - 1;
                return _segmentRow(
                  segments,
                  i,
                  isLast: isLast,
                  flexibleLast: isLast,
                );
              }(),
          ],
        );
      },
    );
  }

  List<Widget> _segmentRow(
    List<String> segments,
    int i, {
    required bool isLast,
    required bool flexibleLast,
  }) {
    final partial =
        '${Platform.pathSeparator}${segments.take(i + 1).join(Platform.pathSeparator)}';
    final segment = _BreadcrumbSegment(
      label: segments[i],
      onTap: isLast ? null : () => widget.store.navigateTo(partial),
      isLast: isLast,
      ellipsisOverflow: flexibleLast,
    );
    return [_caretIcon(), flexibleLast ? Flexible(child: segment) : segment];
  }

  Widget _caretIcon() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: PhosphorIcon(
        PhosphorIconsRegular.caretRight,
        size: 14,
        color: AppColors.fgSubtle,
      ),
    );
  }
}

class _EllipsisMenu extends StatefulWidget {
  final List<int> hiddenIndices;
  final List<String> allSegments;
  final NavigationStore store;

  const _EllipsisMenu({
    required this.hiddenIndices,
    required this.allSegments,
    required this.store,
  });

  @override
  State<_EllipsisMenu> createState() => _EllipsisMenuState();
}

class _EllipsisMenuState extends State<_EllipsisMenu> {
  bool _hovered = false;

  void _openMenu() {
    final box = context.findRenderObject() as RenderBox;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final offset = box.localToGlobal(
      Offset(0, box.size.height + 2),
      ancestor: overlay,
    );

    showContextMenu(
      context: context,
      position: offset,
      items: widget.hiddenIndices
          .map(
            (i) => ContextMenuItem(
              icon: PhosphorIconsRegular.folder,
              label: widget.allSegments[i],
              action: '$i',
            ),
          )
          .toList(),
      onSelect: (action) {
        final i = int.parse(action);
        final partial =
            '${Platform.pathSeparator}${widget.allSegments.take(i + 1).join(Platform.pathSeparator)}';
        widget.store.navigateTo(partial);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: _openMenu,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          decoration: _hovered
              ? BoxDecoration(
                  color: AppColors.bgHover,
                  borderRadius: BorderRadius.circular(3),
                )
              : null,
          child: Tooltip(
            message: widget.hiddenIndices
                .map((i) => widget.allSegments[i])
                .join(' › '),
            child: Text(
              '…',
              style: context.txt.body.copyWith(
                color: _hovered ? AppColors.fg : AppColors.fgMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BreadcrumbSegment extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLast;
  final bool ellipsisOverflow;

  const _BreadcrumbSegment({
    required this.label,
    this.onTap,
    this.isLast = false,
    this.ellipsisOverflow = false,
  });

  @override
  State<_BreadcrumbSegment> createState() => _BreadcrumbSegmentState();
}

class _BreadcrumbSegmentState extends State<_BreadcrumbSegment> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final clickable = widget.onTap != null;
    final text = Text(
      widget.label,
      maxLines: 1,
      softWrap: false,
      overflow: widget.ellipsisOverflow
          ? TextOverflow.ellipsis
          : TextOverflow.clip,
      style: context.txt.body.copyWith(
        color: widget.isLast
            ? AppColors.fg
            : (clickable ? AppColors.fgMuted : AppColors.fg),
        fontWeight: widget.isLast ? FontWeight.w500 : FontWeight.normal,
      ),
    );
    return MouseRegion(
      onEnter: clickable ? (_) => setState(() => _hovered = true) : null,
      onExit: clickable ? (_) => setState(() => _hovered = false) : null,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          decoration: _hovered
              ? BoxDecoration(
                  color: AppColors.bgHover,
                  borderRadius: BorderRadius.circular(3),
                )
              : null,
          child: text,
        ),
      ),
    );
  }
}

class _ViewOptionsButton extends StatefulWidget {
  final NavigationStore store;
  final ShellStore? shellStore;

  const _ViewOptionsButton({required this.store, this.shellStore});

  @override
  State<_ViewOptionsButton> createState() => _ViewOptionsButtonState();
}

class _ViewOptionsButtonState extends State<_ViewOptionsButton> {
  bool _hovered = false;

  void _openMenu() {
    final box = context.findRenderObject() as RenderBox;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final offset = box.localToGlobal(
      Offset(0, box.size.height),
      ancestor: overlay,
    );

    final items = <ContextMenuItem>[
      if (widget.shellStore != null)
        ContextMenuItem(
          icon: PhosphorIconsRegular.columns,
          label: t.menu.dualPaneMode,
          action: 'toggle_dual',
          isToggle: true,
          toggleSignal: widget.shellStore!.isDual,
        ),
      if (widget.shellStore != null) ContextMenuItem.divider,
      ContextMenuItem(
        icon: PhosphorIconsRegular.eye,
        label: t.menu.showHidden,
        action: 'toggle_hidden',
        isToggle: true,
        toggleSignal: widget.store.showHidden,
      ),
    ];

    showContextMenu(
      context: context,
      position: offset,
      items: items,
      onSelect: (action) {
        if (action == 'toggle_hidden') {
          widget.store.showHidden.value = !widget.store.showHidden.value;
        } else if (action == 'toggle_dual') {
          widget.shellStore?.toggleDual();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: t.toolbar.viewOptions,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: _openMenu,
          child: Container(
            width: 30,
            height: 30,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: _hovered ? AppColors.bgHover : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: PhosphorIcon(
              PhosphorIconsRegular.sliders,
              size: 16,
              color: _hovered ? AppColors.fg : AppColors.fgMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _NewFolderButton extends StatefulWidget {
  final NavigationStore store;

  const _NewFolderButton({required this.store});

  @override
  State<_NewFolderButton> createState() => _NewFolderButtonState();
}

class _NewFolderButtonState extends State<_NewFolderButton> {
  bool _hovered = false;

  void _createFolder() {
    widget.store.startCreate();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: t.toolbar.newFolder,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: _createFolder,
          child: Container(
            width: 30,
            height: 30,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: _hovered ? AppColors.bgHover : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: PhosphorIcon(
              PhosphorIconsRegular.folderPlus,
              size: 16,
              color: _hovered ? AppColors.fg : AppColors.fgMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _OperationsButton extends StatefulWidget {
  final NavigationStore store;

  const _OperationsButton({required this.store});

  @override
  State<_OperationsButton> createState() => _OperationsButtonState();
}

class _OperationsButtonState extends State<_OperationsButton>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  void _openPanel() {
    final box = context.findRenderObject() as RenderBox;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final offset = box.localToGlobal(
      Offset(0, box.size.height),
      ancestor: overlay,
    );

    showOperationsPanel(
      context: context,
      position: offset,
      operationStore: widget.store.operationStore,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final count = widget.store.operationStore.activeCount.value;
      if (count == 0) {
        if (_spin.isAnimating) _spin.stop();
        return const SizedBox.shrink();
      }
      if (!_spin.isAnimating) _spin.repeat();

      return Tooltip(
        message: t.toolbar.operations,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTap: _openPanel,
            child: Container(
              width: 30,
              height: 30,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: _hovered
                    ? AppColors.accent.withValues(alpha: 0.22)
                    : AppColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.55),
                  width: 1,
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: RotationTransition(
                      turns: _spin,
                      child: PhosphorIcon(
                        PhosphorIconsRegular.circleNotch,
                        size: 14,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 1,
                    top: 1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                      child: Center(
                        child: Text('$count', style: context.txt.badge),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _NotificationsButton extends StatefulWidget {
  final NotificationStore notificationStore;

  const _NotificationsButton({required this.notificationStore});

  @override
  State<_NotificationsButton> createState() => _NotificationsButtonState();
}

class _NotificationsButtonState extends State<_NotificationsButton> {
  bool _hovered = false;

  void _open() {
    final box = context.findRenderObject() as RenderBox;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final offset = box.localToGlobal(
      Offset(0, box.size.height),
      ancestor: overlay,
    );

    showNotificationsPanel(
      context: context,
      position: offset,
      store: widget.notificationStore,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: t.toolbar.notifications,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: _open,
          child: Container(
            width: 30,
            height: 30,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: _hovered ? AppColors.bgHover : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Center(
                  child: PhosphorIcon(
                    PhosphorIconsRegular.bell,
                    size: 16,
                    color: _hovered ? AppColors.fg : AppColors.fgMuted,
                  ),
                ),
                Watch((context) {
                  final count = widget.notificationStore.history.value.length;
                  if (count == 0) return const SizedBox.shrink();
                  return Positioned(
                    right: 4,
                    top: 6,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
