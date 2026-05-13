import 'dart:io' show Platform;

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../app/app_info.dart';
import '../../app/waydir_app.dart';
import '../../features/settings/keybindings_help_view.dart';
import '../../features/settings/preferences_view.dart';
import '../../i18n/strings.g.dart';
import '../overlays/context_menu.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';

void _openPreferences() {
  final ctx = waydirNavigatorKey.currentContext;
  if (ctx != null) showPreferencesDialog(ctx);
}

void _openKeybindingsHelp() {
  final ctx = waydirNavigatorKey.currentContext;
  if (ctx != null) showKeybindingsHelp(ctx);
}

class TitleBar extends StatelessWidget {
  final Widget child;

  const TitleBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (Platform.isMacOS) {
      return PlatformMenuBar(menus: _platformMenus(), child: child);
    }
    return Column(
      children: [
        const _TitleBarRow(),
        Expanded(child: child),
      ],
    );
  }

  List<PlatformMenuItem> _platformMenus() {
    return [
      PlatformMenu(
        label: 'Waydir',
        menus: [
          PlatformMenuItemGroup(
            members: [
              PlatformMenuItem(
                label: t.preferences.menuLabel,
                shortcut: const SingleActivator(
                  LogicalKeyboardKey.comma,
                  meta: true,
                ),
                onSelected: _openPreferences,
              ),
            ],
          ),
          PlatformMenuItemGroup(
            members: [
              PlatformMenuItem(
                label: t.keybindings.menuLabel,
                shortcut: const SingleActivator(
                  LogicalKeyboardKey.slash,
                  meta: true,
                ),
                onSelected: _openKeybindingsHelp,
              ),
            ],
          ),
          PlatformMenuItemGroup(
            members: [
              PlatformMenuItem(
                label: t.appMenu.quit,
                shortcut: const SingleActivator(
                  LogicalKeyboardKey.keyQ,
                  meta: true,
                ),
                onSelected: SystemNavigator.pop,
              ),
            ],
          ),
        ],
      ),
    ];
  }
}

class _TitleBarRow extends StatelessWidget {
  const _TitleBarRow();

  @override
  Widget build(BuildContext context) {
    return WindowTitleBarBox(
      child: Container(
        height: 32,
        decoration: const BoxDecoration(
          color: AppColors.bgSidebar,
          border: Border(bottom: BorderSide(color: AppColors.bgDivider)),
        ),
        child: Row(
          children: [
            const SizedBox(width: 10),
            Image.asset(AppInfo.iconAsset, width: 14, height: 14),
            const SizedBox(width: 8),
            const _MenuBar(),
            Expanded(child: MoveWindow()),
            const _WindowButtons(),
          ],
        ),
      ),
    );
  }
}

class _MenuBar extends StatelessWidget {
  const _MenuBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MenuButton(
          label: 'Waydir',
          items: [
            ContextMenuItem(
              icon: PhosphorIconsRegular.gearSix,
              label: t.preferences.menuLabel,
              action: 'preferences',
            ),
            ContextMenuItem(
              icon: PhosphorIconsRegular.keyboard,
              label: t.keybindings.menuLabel,
              action: 'keybindings',
            ),
            ContextMenuItem.divider,
            ContextMenuItem(
              icon: PhosphorIconsRegular.signOut,
              label: t.appMenu.quit,
              action: 'quit',
            ),
          ],
          onSelect: (action) {
            switch (action) {
              case 'preferences':
                _openPreferences();
              case 'keybindings':
                _openKeybindingsHelp();
              case 'quit':
                SystemNavigator.pop();
            }
          },
        ),
      ],
    );
  }
}

class _MenuButton extends StatefulWidget {
  final String label;
  final List<ContextMenuItem> items;
  final void Function(String action) onSelect;

  const _MenuButton({
    required this.label,
    required this.items,
    required this.onSelect,
  });

  @override
  State<_MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<_MenuButton> {
  final _key = GlobalKey();
  bool _hovered = false;

  void _open() {
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final pos = box.localToGlobal(Offset(0, box.size.height));
    showContextMenu(
      context: context,
      position: pos,
      items: widget.items,
      onSelect: widget.onSelect,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        key: _key,
        onTap: _open,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          color: _hovered ? AppColors.bgHover : Colors.transparent,
          alignment: Alignment.center,
          child: Text(widget.label, style: context.txt.bodyEmphasis),
        ),
      ),
    );
  }
}

class _WindowButtons extends StatelessWidget {
  const _WindowButtons();

  static const _iconColor = AppColors.fgMuted;
  static const _iconHoverColor = AppColors.fg;

  static final _btnColors = WindowButtonColors(
    iconNormal: _iconColor,
    iconMouseOver: _iconHoverColor,
    mouseOver: AppColors.bgHover,
    mouseDown: AppColors.bgSurface,
  );

  static final _closeColors = WindowButtonColors(
    iconNormal: _iconColor,
    iconMouseOver: Colors.white,
    mouseOver: AppColors.windowCloseHover,
    mouseDown: AppColors.windowClosePressed,
  );

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MinimizeWindowButton(colors: _btnColors, animate: false),
        MaximizeWindowButton(colors: _btnColors, animate: false),
        CloseWindowButton(colors: _closeColors, animate: false),
      ],
    );
  }
}
