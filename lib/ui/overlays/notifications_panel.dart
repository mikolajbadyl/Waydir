import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:signals/signals_flutter.dart';
import '../../core/models/app_notification.dart';
import '../../i18n/strings.g.dart';
import '../../utils/format.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';
import 'notification_store.dart';
import 'popup_overlay.dart';

void showNotificationsPanel({
  required BuildContext context,
  required Offset position,
  required NotificationStore store,
}) {
  showPopup(
    context: context,
    position: position,
    width: 360,
    autoDismiss: true,
    builder: (_) => _NotificationsPanelBody(store: store),
  );
}

class _NotificationsPanelBody extends StatelessWidget {
  final NotificationStore store;

  const _NotificationsPanelBody({required this.store});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      constraints: const BoxConstraints(maxHeight: 520),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                PhosphorIcon(
                  PhosphorIconsRegular.bell,
                  size: 16,
                  color: AppColors.fgMuted,
                ),
                const SizedBox(width: 8),
                Text(t.notifications.title, style: context.txt.dialogTitle),
                const Spacer(),
                Watch((context) {
                  final has = store.history.value.isNotEmpty;
                  if (!has) return const SizedBox.shrink();
                  return _ClearButton(onTap: () => store.clearHistory());
                }),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: AppColors.bgDivider),
          Watch((context) {
            final items = store.history.value;
            if (items.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  t.notifications.empty,
                  style: context.txt.body.copyWith(color: AppColors.fgSubtle),
                ),
              );
            }
            final reversed = items.reversed.toList();
            return Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: reversed.length,
                separatorBuilder: (_, _) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.bgDivider,
                  ),
                ),
                itemBuilder: (_, i) => _NotificationTile(
                  notification: reversed[i],
                  onRemove: () => store.removeFromHistory(reversed[i].id),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ClearButton extends StatefulWidget {
  final VoidCallback onTap;
  const _ClearButton({required this.onTap});

  @override
  State<_ClearButton> createState() => _ClearButtonState();
}

class _ClearButtonState extends State<_ClearButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Text(
          t.notifications.clear,
          style: context.txt.row.copyWith(
            color: _hovered ? AppColors.accentHover : AppColors.accent,
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatefulWidget {
  final AppNotification notification;
  final VoidCallback onRemove;

  const _NotificationTile({required this.notification, required this.onRemove});

  @override
  State<_NotificationTile> createState() => _NotificationTileState();
}

class _NotificationTileState extends State<_NotificationTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final n = widget.notification;
    final accent = n.accentColor ?? AppColors.accent;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        color: _hovered ? AppColors.bgHover : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (n.icon != null) ...[
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: PhosphorIcon(n.icon!, size: 14, color: accent),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (n.title != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        n.title!,
                        style: context.txt.rowEmphasis.copyWith(color: accent),
                      ),
                    ),
                  Text(
                    n.message,
                    style: context.txt.row.copyWith(height: 1.35),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    formatTimeAgo(n.timestamp),
                    style: context.txt.caption.copyWith(
                      color: AppColors.fgSubtle,
                    ),
                  ),
                ],
              ),
            ),
            if (_hovered)
              GestureDetector(
                onTap: widget.onRemove,
                child: Padding(
                  padding: const EdgeInsets.only(left: 6, top: 2),
                  child: PhosphorIcon(
                    PhosphorIconsRegular.x,
                    size: 12,
                    color: AppColors.fgMuted,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
