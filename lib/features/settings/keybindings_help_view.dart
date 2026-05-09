import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../i18n/strings.g.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/theme/app_text_styles.dart';

Future<void> showKeybindingsHelp(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (ctx) => const _KeybindingsHelpDialog(),
  );
}

class _ShortcutEntry {
  final String keys;
  final String Function() label;
  final String Function()? hint;

  const _ShortcutEntry({required this.keys, required this.label, this.hint});
}

class _ShortcutGroup {
  final String Function() title;
  final IconData icon;
  final List<_ShortcutEntry> entries;

  const _ShortcutGroup({
    required this.title,
    required this.icon,
    required this.entries,
  });
}

final _groups = <_ShortcutGroup>[
  _ShortcutGroup(
    title: () => t.keybindings.categories.navigation,
    icon: PhosphorIconsRegular.compass,
    entries: [
      _ShortcutEntry(keys: 'Enter', label: () => t.keybindings.openItem),
      _ShortcutEntry(keys: 'Backspace', label: () => t.keybindings.goUp),
      _ShortcutEntry(keys: 'Alt+←', label: () => t.keybindings.goBack),
      _ShortcutEntry(keys: 'Alt+→', label: () => t.keybindings.goForward),
      _ShortcutEntry(keys: '↑', label: () => t.keybindings.cursorUp),
      _ShortcutEntry(keys: '↓', label: () => t.keybindings.cursorDown),
    ],
  ),
  _ShortcutGroup(
    title: () => t.keybindings.categories.tabs,
    icon: PhosphorIconsRegular.tabs,
    entries: [
      _ShortcutEntry(keys: 'Ctrl+T', label: () => t.keybindings.newTab),
      _ShortcutEntry(keys: 'Ctrl+W', label: () => t.keybindings.closeTab),
      _ShortcutEntry(keys: 'Ctrl+Tab', label: () => t.keybindings.nextTab),
      _ShortcutEntry(keys: 'Ctrl+Shift+Tab', label: () => t.keybindings.prevTab),
      _ShortcutEntry(keys: 'Ctrl+1…9', label: () => t.keybindings.switchTab),
    ],
  ),
  _ShortcutGroup(
    title: () => t.keybindings.categories.panes,
    icon: PhosphorIconsRegular.columns,
    entries: [
      _ShortcutEntry(keys: 'F9 / Ctrl+Shift+D', label: () => t.keybindings.toggleDual),
      _ShortcutEntry(keys: 'Tab', label: () => t.keybindings.switchPane),
    ],
  ),
  _ShortcutGroup(
    title: () => t.keybindings.categories.fileOps,
    icon: PhosphorIconsRegular.copy,
    entries: [
      _ShortcutEntry(keys: 'Ctrl+C', label: () => t.keybindings.copy),
      _ShortcutEntry(keys: 'Ctrl+X', label: () => t.keybindings.cut),
      _ShortcutEntry(keys: 'Ctrl+V', label: () => t.keybindings.paste),
      _ShortcutEntry(keys: 'Delete', label: () => t.keybindings.delete),
      _ShortcutEntry(keys: 'F2', label: () => t.keybindings.rename),
      _ShortcutEntry(keys: 'F7', label: () => t.keybindings.newFolder),
      _ShortcutEntry(keys: 'F5', label: () => t.keybindings.dualCopy, hint: () => 'dual'),
      _ShortcutEntry(keys: 'F6', label: () => t.keybindings.dualMove, hint: () => 'dual'),
    ],
  ),
  _ShortcutGroup(
    title: () => t.keybindings.categories.selection,
    icon: PhosphorIconsRegular.checkSquare,
    entries: [
      _ShortcutEntry(keys: 'Ctrl+A', label: () => t.keybindings.selectAll),
      _ShortcutEntry(keys: 'Esc', label: () => t.keybindings.deselectAll),
      _ShortcutEntry(keys: 'Insert', label: () => t.keybindings.toggleSelect),
    ],
  ),
  _ShortcutGroup(
    title: () => t.keybindings.categories.search,
    icon: PhosphorIconsRegular.magnifyingGlass,
    entries: [
      _ShortcutEntry(keys: 'Ctrl+F', label: () => t.keybindings.search),
      _ShortcutEntry(keys: 'Ctrl+Shift+F', label: () => t.keybindings.recursiveSearch),
      _ShortcutEntry(keys: 'Esc', label: () => t.keybindings.closeSearch),
    ],
  ),
];

class _KeybindingsHelpDialog extends StatefulWidget {
  const _KeybindingsHelpDialog();

  @override
  State<_KeybindingsHelpDialog> createState() => _KeybindingsHelpDialogState();
}

class _KeybindingsHelpDialogState extends State<_KeybindingsHelpDialog> {
  String _query = '';
  final _searchCtl = TextEditingController();

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  List<_ShortcutGroup> _filtered() {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _groups;
    final out = <_ShortcutGroup>[];
    for (final g in _groups) {
      final matches = g.entries.where((e) {
        return e.label().toLowerCase().contains(q) ||
            e.keys.toLowerCase().contains(q) ||
            g.title().toLowerCase().contains(q);
      }).toList();
      if (matches.isNotEmpty) {
        out.add(_ShortcutGroup(title: g.title, icon: g.icon, entries: matches));
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width.clamp(360.0, 560.0).toDouble();
    final height = (size.height * 0.9).clamp(360.0, 720.0).toDouble();
    final groups = _filtered();

    return Center(
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Column(
              children: [
                _Header(onClose: () => Navigator.of(context).pop()),
                Container(height: 1, color: AppColors.bgDivider),
                _SearchBar(
                  controller: _searchCtl,
                  onChanged: (v) => setState(() => _query = v),
                ),
                Container(height: 1, color: AppColors.bgDivider),
                Expanded(
                  child: groups.isEmpty
                      ? const _EmptyState()
                      : _ShortcutGrid(groups: groups),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onClose;
  const _Header({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(color: AppColors.bgSidebar),
      child: Row(
        children: [
          const PhosphorIcon(PhosphorIconsRegular.keyboard,
              size: 16, color: AppColors.fgAccent),
          const SizedBox(width: 8),
          Text(
            t.keybindings.title,
            style: context.txt.dialogTitle,
          ),
          const Spacer(),
          _CloseButton(onTap: onClose),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      color: AppColors.bgSurface,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.bgInput,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Row(
          children: [
            const PhosphorIcon(PhosphorIconsRegular.magnifyingGlass,
                size: 13, color: AppColors.fgSubtle),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                autofocus: true,
                onChanged: onChanged,
                style: context.txt.row,
                cursorColor: AppColors.fg,
                cursorWidth: 1,
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: t.search.placeholder,
                  hintStyle: context.txt.row.copyWith(color: AppColors.fgSubtle),
                ),
              ),
            ),
            if (controller.text.isNotEmpty)
              _ClearButton(onTap: () {
                controller.clear();
                onChanged('');
              }),
          ],
        ),
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
        child: PhosphorIcon(
          PhosphorIconsRegular.x,
          size: 12,
          color: _hovered ? AppColors.fg : AppColors.fgSubtle,
        ),
      ),
    );
  }
}

class _CloseButton extends StatefulWidget {
  final VoidCallback onTap;
  const _CloseButton({required this.onTap});

  @override
  State<_CloseButton> createState() => _CloseButtonState();
}

class _CloseButtonState extends State<_CloseButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _hovered ? AppColors.bgHover : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: PhosphorIcon(PhosphorIconsRegular.x,
              size: 14,
              color: _hovered ? AppColors.fg : AppColors.fgMuted),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PhosphorIcon(PhosphorIconsRegular.magnifyingGlass,
              size: 28, color: AppColors.fgSubtle),
          const SizedBox(height: 10),
          Text(
            t.search.noMatches,
            style: context.txt.muted,
          ),
        ],
      ),
    );
  }
}

class _ShortcutGrid extends StatelessWidget {
  final List<_ShortcutGroup> groups;
  const _ShortcutGrid({required this.groups});

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    for (int g = 0; g < groups.length; g++) {
      final group = groups[g];
      items.add(_GroupHeader(group: group, isFirst: g == 0));
      for (final entry in group.entries) {
        items.add(_ShortcutRow(entry: entry));
      }
    }
    return ListView(
      padding: EdgeInsets.zero,
      children: items,
    );
  }
}

class _GroupHeader extends StatelessWidget {
  final _ShortcutGroup group;
  final bool isFirst;
  const _GroupHeader({required this.group, required this.isFirst});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, isFirst ? 14 : 22, 16, 6),
      child: Row(
        children: [
          PhosphorIcon(group.icon, size: 12, color: AppColors.fgMuted),
          const SizedBox(width: 7),
          Text(
            group.title().toUpperCase(),
            style: context.txt.sectionLabel,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(height: 1, color: AppColors.bgDivider),
          ),
        ],
      ),
    );
  }
}

class _ShortcutRow extends StatefulWidget {
  final _ShortcutEntry entry;
  const _ShortcutRow({required this.entry});

  @override
  State<_ShortcutRow> createState() => _ShortcutRowState();
}

class _ShortcutRowState extends State<_ShortcutRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        color: _hovered ? AppColors.bgHover : Colors.transparent,
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      widget.entry.label(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.txt.row,
                    ),
                  ),
                  if (widget.entry.hint != null) ...[
                    const SizedBox(width: 6),
                    Text(
                      widget.entry.hint!(),
                      style: context.txt.caption.copyWith(fontStyle: FontStyle.italic),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            _KeyBadge(keys: widget.entry.keys),
          ],
        ),
      ),
    );
  }
}

class _KeyBadge extends StatelessWidget {
  final String keys;
  const _KeyBadge({required this.keys});

  @override
  Widget build(BuildContext context) {
    final alternates = keys.split(RegExp(r'\s*/\s*'));
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int a = 0; a < alternates.length; a++) ...[
          if (a > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                'or',
                style: context.txt.micro,
              ),
            ),
          ..._renderCombo(context, alternates[a]),
        ],
      ],
    );
  }

  List<Widget> _renderCombo(BuildContext context, String combo) {
    final parts = combo.split(RegExp(r'\s*\+\s*'));
    final widgets = <Widget>[];
    for (int i = 0; i < parts.length; i++) {
      if (i > 0) {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Text(
            '+',
            style: context.txt.caption.copyWith(height: 1.2),
          ),
        ));
      }
      widgets.add(_KeyCap(text: parts[i]));
    }
    return widgets;
  }
}

class _KeyCap extends StatelessWidget {
  final String text;
  const _KeyCap({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 22),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.bgInput,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 0,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: context.txt.keyCap,
      ),
    );
  }
}
