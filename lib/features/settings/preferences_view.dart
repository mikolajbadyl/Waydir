import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:signals/signals_flutter.dart';

import '../../core/settings/settings_store.dart';
import '../../core/terminal/terminal.dart';
import '../../i18n/strings.g.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/theme/app_text_styles.dart';
import '../../ui/widgets/app_dropdown.dart';

Future<void> showPreferencesDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (ctx) => const _PreferencesDialog(),
  );
}

enum _Category {
  general,
  appearance,
  terminal,
  shortcuts,
  fileAssociations,
  bookmarks,
  about,
}

class _CategoryMeta {
  final _Category id;
  final IconData icon;
  final String Function() label;
  final bool comingSoon;

  const _CategoryMeta(
    this.id,
    this.icon,
    this.label, {
    this.comingSoon = false,
  });
}

final _categories = <_CategoryMeta>[
  _CategoryMeta(
    _Category.general,
    PhosphorIconsRegular.slidersHorizontal,
    () => t.preferences.categories.general,
    comingSoon: true,
  ),
  _CategoryMeta(
    _Category.appearance,
    PhosphorIconsRegular.palette,
    () => t.preferences.categories.appearance,
    comingSoon: true,
  ),
  _CategoryMeta(
    _Category.terminal,
    PhosphorIconsRegular.terminal,
    () => t.preferences.categories.terminal,
  ),
  _CategoryMeta(
    _Category.shortcuts,
    PhosphorIconsRegular.keyboard,
    () => t.preferences.categories.shortcuts,
    comingSoon: true,
  ),
  _CategoryMeta(
    _Category.fileAssociations,
    PhosphorIconsRegular.fileArrowUp,
    () => t.preferences.categories.fileAssociations,
    comingSoon: true,
  ),
  _CategoryMeta(
    _Category.bookmarks,
    PhosphorIconsRegular.bookmarkSimple,
    () => t.preferences.categories.bookmarks,
    comingSoon: true,
  ),
  _CategoryMeta(
    _Category.about,
    PhosphorIconsRegular.info,
    () => t.preferences.categories.about,
    comingSoon: true,
  ),
];

class _PreferencesDialog extends StatefulWidget {
  const _PreferencesDialog();

  @override
  State<_PreferencesDialog> createState() => _PreferencesDialogState();
}

class _PreferencesDialogState extends State<_PreferencesDialog> {
  _Category _selected = _Category.terminal;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Center(
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          width: size.width * 0.9,
          height: size.height * 0.9,
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.circular(8),
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
            borderRadius: BorderRadius.circular(8),
            child: Column(
              children: [
                _Header(onClose: () => Navigator.of(context).pop()),
                Container(height: 1, color: AppColors.bgDivider),
                Expanded(
                  child: Row(
                    children: [
                      _CategorySidebar(
                        selected: _selected,
                        onSelect: (c) => setState(() => _selected = c),
                      ),
                      Container(width: 1, color: AppColors.bgDivider),
                      Expanded(child: _ContentPane(category: _selected)),
                    ],
                  ),
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
          PhosphorIcon(
            PhosphorIconsRegular.gearSix,
            size: 16,
            color: AppColors.fgAccent,
          ),
          const SizedBox(width: 8),
          Text(t.preferences.title, style: context.txt.dialogTitle),
          const Spacer(),
          _CloseButton(onTap: onClose),
        ],
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
          child: PhosphorIcon(
            PhosphorIconsRegular.x,
            size: 14,
            color: _hovered ? AppColors.fg : AppColors.fgMuted,
          ),
        ),
      ),
    );
  }
}

class _CategorySidebar extends StatelessWidget {
  final _Category selected;
  final ValueChanged<_Category> onSelect;

  const _CategorySidebar({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      color: AppColors.bgSidebar,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      child: ListView(
        children: [
          for (final cat in _categories)
            _CategoryItem(
              meta: cat,
              selected: cat.id == selected,
              onTap: () => onSelect(cat.id),
            ),
        ],
      ),
    );
  }
}

class _CategoryItem extends StatefulWidget {
  final _CategoryMeta meta;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryItem({
    required this.meta,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_CategoryItem> createState() => _CategoryItemState();
}

class _CategoryItemState extends State<_CategoryItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.selected
        ? AppColors.bgSelectedMuted
        : (_hovered ? AppColors.bgHover : Colors.transparent);
    final fg = widget.selected ? AppColors.fg : AppColors.fgMuted;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 28,
          margin: const EdgeInsets.symmetric(vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(4),
            border: widget.selected
                ? const Border(
                    left: BorderSide(color: AppColors.accent, width: 2),
                  )
                : null,
          ),
          child: Row(
            children: [
              PhosphorIcon(widget.meta.icon, size: 14, color: fg),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.meta.label(),
                  style: context.txt.body.copyWith(
                    color: fg,
                    fontWeight: widget.selected
                        ? FontWeight.w500
                        : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.meta.comingSoon)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.bgInput,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    'soon',
                    style: context.txt.caption.copyWith(
                      color: AppColors.fgSubtle,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContentPane extends StatelessWidget {
  final _Category category;
  const _ContentPane({required this.category});

  @override
  Widget build(BuildContext context) {
    final meta = _categories.firstWhere((c) => c.id == category);
    if (meta.comingSoon) return _ComingSoonPane(meta: meta);
    switch (category) {
      case _Category.terminal:
        return const _TerminalPane();
      default:
        return _ComingSoonPane(meta: meta);
    }
  }
}

class _ComingSoonPane extends StatelessWidget {
  final _CategoryMeta meta;
  const _ComingSoonPane({required this.meta});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PhosphorIcon(meta.icon, size: 36, color: AppColors.fgSubtle),
          const SizedBox(height: 12),
          Text(
            meta.label(),
            style: context.txt.dialogTitle.copyWith(
              color: AppColors.fgMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            t.preferences.comingSoon,
            style: context.txt.muted.copyWith(color: AppColors.fgSubtle),
          ),
        ],
      ),
    );
  }
}

class _TerminalPane extends StatefulWidget {
  const _TerminalPane();

  @override
  State<_TerminalPane> createState() => _TerminalPaneState();
}

class _TerminalPaneState extends State<_TerminalPane> {
  late Future<List<TerminalSpec>> _detected;
  late final TextEditingController _customController;

  @override
  void initState() {
    super.initState();
    _detected = TerminalService.detectAvailable();
    _customController = TextEditingController(
      text: SettingsStore.instance.terminalCustomCommand.value,
    );
    _customController.addListener(() {
      SettingsStore.instance.terminalCustomCommand.value =
          _customController.text;
    });
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.preferences.terminal.title, style: context.txt.pageTitle),
          const SizedBox(height: 4),
          Text(t.preferences.terminal.subtitle, style: context.txt.muted),
          const SizedBox(height: 20),
          Text(t.preferences.terminal.label, style: context.txt.fieldLabel),
          const SizedBox(height: 8),
          FutureBuilder<List<TerminalSpec>>(
            future: _detected,
            builder: (context, snapshot) {
              final detected = snapshot.data ?? const <TerminalSpec>[];
              return Watch((context) {
                final current = SettingsStore.instance.terminal.value;
                return _TerminalDropdown(
                  current: current,
                  detected: detected,
                  onChanged: (id) => SettingsStore.instance.terminal.value = id,
                );
              });
            },
          ),
          Watch((context) {
            final current = SettingsStore.instance.terminal.value;
            if (current != 'custom') return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _CustomCommandField(controller: _customController),
            );
          }),
        ],
      ),
    );
  }
}

class _TerminalDropdown extends StatelessWidget {
  final String current;
  final List<TerminalSpec> detected;
  final ValueChanged<String> onChanged;

  const _TerminalDropdown({
    required this.current,
    required this.detected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final items = <AppDropdownItem<String>>[
      AppDropdownItem(
        value: 'auto',
        label: t.preferences.terminal.auto,
        icon: PhosphorIconsRegular.magicWand,
      ),
      for (final spec in detected)
        AppDropdownItem(
          value: spec.id,
          label: spec.displayName,
          icon: PhosphorIconsRegular.terminal,
        ),
      AppDropdownItem(
        value: 'custom',
        label: t.preferences.terminal.custom,
        icon: PhosphorIconsRegular.code,
      ),
    ];

    final values = items.map((e) => e.value).toSet();
    final value = values.contains(current) ? current : 'auto';

    return SizedBox(
      width: 360,
      child: AppDropdown<String>(
        value: value,
        items: items,
        onChanged: onChanged,
      ),
    );
  }
}

class _CustomCommandField extends StatelessWidget {
  final TextEditingController controller;
  const _CustomCommandField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.preferences.terminal.customLabel, style: context.txt.fieldLabel),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: context.txt.body,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            hintText: t.preferences.terminal.customHint,
            hintStyle: context.txt.body.copyWith(color: AppColors.fgSubtle),
            filled: true,
            fillColor: AppColors.bgInput,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: AppColors.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: AppColors.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: AppColors.accent),
            ),
          ),
          cursorColor: AppColors.accent,
        ),
        const SizedBox(height: 6),
        Text(
          t.preferences.terminal.customHelp,
          style: context.txt.captionSmall.copyWith(color: AppColors.fgSubtle),
        ),
      ],
    );
  }
}
