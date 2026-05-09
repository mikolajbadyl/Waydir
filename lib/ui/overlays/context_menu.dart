import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:signals/signals_flutter.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';
import 'popup_overlay.dart';

class ContextMenuItem {
  final IconData icon;
  final String label;
  final String action;
  final bool danger;
  final bool isToggle;
  final Signal<bool>? toggleSignal;
  final String? shortcut;

  const ContextMenuItem({
    required this.icon,
    required this.label,
    required this.action,
    this.danger = false,
    this.isToggle = false,
    this.toggleSignal,
    this.shortcut,
  });

  static const divider = ContextMenuItem._divider();

  const ContextMenuItem._divider()
      : icon = const IconData(0),
        label = '',
        action = '__divider__',
        danger = false,
        isToggle = false,
        toggleSignal = null,
        shortcut = null;

  bool get isDivider => action == '__divider__';
}

void showContextMenu({
  required BuildContext context,
  required Offset position,
  required List<ContextMenuItem> items,
  required void Function(String action) onSelect,
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;

  void dismiss() {
    if (entry.mounted) entry.remove();
  }

  entry = OverlayEntry(
    builder: (_) => PopupOverlay(
      position: position,
      width: 180,
      autoDismiss: true,
      onDismiss: dismiss,
      builder: (_) => _ContextMenuBody(
        items: items,
        onSelect: (action) {
          final item = items.firstWhere(
            (i) => !i.isDivider && i.action == action,
            orElse: () => items.first,
          );
          onSelect(action);
          if (!item.isToggle) dismiss();
        },
      ),
    ),
  );

  overlay.insert(entry);
}

class _ContextMenuBody extends StatelessWidget {
  final List<ContextMenuItem> items;
  final void Function(String action) onSelect;

  const _ContextMenuBody({
    required this.items,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 180, maxWidth: 360),
      child: IntrinsicWidth(
        child: Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: items.asMap().entries.map((e) {
            if (e.value.isDivider) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                child: Divider(
                    height: 1, thickness: 1, color: AppColors.bgDivider),
              );
            }
            return _ContextMenuItemTile(
              item: e.value,
              onTap: () => onSelect(e.value.action),
            );
          }).toList(),
        ),
      ),
    ),
      ),
    );
  }
}

class _ContextMenuItemTile extends StatefulWidget {
  final ContextMenuItem item;
  final VoidCallback onTap;

  const _ContextMenuItemTile({
    required this.item,
    required this.onTap,
  });

  @override
  State<_ContextMenuItemTile> createState() => _ContextMenuItemTileState();
}

class _ContextMenuItemTileState extends State<_ContextMenuItemTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final dangerColor = AppColors.danger;
    final hoverBg = item.danger
        ? dangerColor.withValues(alpha: 0.12)
        : const Color(0xFF333639);
    final fg = _hovered
        ? (item.danger ? dangerColor : AppColors.fg)
        : AppColors.fgMuted;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: _hovered ? hoverBg : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              PhosphorIcon(item.icon, size: 14, color: fg),
              const SizedBox(width: 8),
              Text(item.label,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: context.txt.body.copyWith(color: fg)),
              const Spacer(),
              if (item.shortcut != null) ...[
                const SizedBox(width: 16),
                Text(item.shortcut!,
                    maxLines: 1,
                    softWrap: false,
                    style: context.txt.captionSmall.copyWith(
                        color: fg.withValues(alpha: 0.5))),
              ],
              if (item.isToggle && item.toggleSignal != null) ...[
                const SizedBox(width: 8),
                Watch((_) => _Checkbox(value: item.toggleSignal!.value)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Checkbox extends StatelessWidget {
  final bool value;

  const _Checkbox({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: value ? AppColors.accent : Colors.transparent,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: value ? AppColors.accent : AppColors.borderColor,
          width: 1,
        ),
      ),
      child: value
          ? PhosphorIcon(PhosphorIconsRegular.check,
              size: 10, color: Colors.white)
          : null,
    );
  }
}
