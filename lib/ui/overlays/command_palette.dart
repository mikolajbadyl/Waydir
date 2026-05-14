import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../i18n/strings.g.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';

class CommandPaletteAction {
  final IconData icon;
  final String title;
  final String subtitle;
  final String searchText;
  final VoidCallback run;

  const CommandPaletteAction({
    required this.icon,
    required this.title,
    this.subtitle = '',
    this.searchText = '',
    required this.run,
  });

  bool matches(String query) {
    final haystack = '$title $subtitle $searchText'.toLowerCase();
    return query.split(RegExp(r'\s+')).every(haystack.contains);
  }
}

Future<void> showCommandPalette({
  required BuildContext context,
  required List<CommandPaletteAction> actions,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: t.commandPalette.title,
    barrierColor: Colors.black.withValues(alpha: 0.42),
    transitionDuration: const Duration(milliseconds: 120),
    pageBuilder: (context, animation, secondaryAnimation) {
      return _CommandPalette(actions: actions);
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.03),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _CommandPalette extends StatefulWidget {
  final List<CommandPaletteAction> actions;

  const _CommandPalette({required this.actions});

  @override
  State<_CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<_CommandPalette> {
  final _queryController = TextEditingController();
  final _queryFocus = FocusNode();
  int _selected = 0;

  @override
  void initState() {
    super.initState();
    _queryController.addListener(() => setState(() => _selected = 0));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _queryFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _queryController.dispose();
    _queryFocus.dispose();
    super.dispose();
  }

  List<CommandPaletteAction> _entries() {
    final query = _queryController.text.trim().toLowerCase();
    if (query.isEmpty) return widget.actions;
    return widget.actions.where((entry) => entry.matches(query)).toList();
  }

  void _run(CommandPaletteAction action) {
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) => action.run());
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final entries = _entries();
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (entries.isNotEmpty) {
        setState(() => _selected = (_selected + 1) % entries.length);
      }
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (entries.isNotEmpty) {
        setState(
          () => _selected = (_selected - 1 + entries.length) % entries.length,
        );
      }
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (entries.isNotEmpty) {
        final index = _selected.clamp(0, entries.length - 1).toInt();
        _run(entries[index]);
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 42),
        child: Material(
          color: Colors.transparent,
          child: Focus(
            onKeyEvent: _handleKey,
            child: Container(
              width: width.clamp(320.0, 640.0).toDouble(),
              constraints: const BoxConstraints(maxHeight: 460),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.55),
                    blurRadius: 26,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SearchField(
                      controller: _queryController,
                      focusNode: _queryFocus,
                    ),
                    Container(height: 1, color: AppColors.bgDivider),
                    Flexible(
                      child: ListenableBuilder(
                        listenable: _queryController,
                        builder: (context, _) {
                          final entries = _entries();
                          if (_selected >= entries.length) _selected = 0;
                          if (entries.isEmpty) return const _EmptyState();
                          return ListView.builder(
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            itemCount: entries.length,
                            itemBuilder: (context, index) {
                              return _PaletteRow(
                                entry: entries[index],
                                selected: index == _selected,
                                onHover: () =>
                                    setState(() => _selected = index),
                                onRun: () => _run(entries[index]),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;

  const _SearchField({required this.controller, required this.focusNode});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          const SizedBox(width: 14),
          PhosphorIcon(
            PhosphorIconsRegular.magnifyingGlass,
            size: 18,
            color: AppColors.fgMuted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: true,
              style: context.txt.body,
              decoration: InputDecoration(
                hintText: t.commandPalette.placeholder,
                hintStyle: context.txt.body.copyWith(color: AppColors.fgMuted),
                border: InputBorder.none,
                isDense: true,
              ),
              cursorColor: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaletteRow extends StatelessWidget {
  final CommandPaletteAction entry;
  final bool selected;
  final VoidCallback onHover;
  final VoidCallback onRun;

  const _PaletteRow({
    required this.entry,
    required this.selected,
    required this.onHover,
    required this.onRun,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.fg : AppColors.fgMuted;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => onHover(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onRun,
        child: Container(
          height: 46,
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.bgSelectedMuted : Colors.transparent,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Row(
            children: [
              PhosphorIcon(entry.icon, size: 17, color: fg),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      style: context.txt.body.copyWith(color: AppColors.fg),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (entry.subtitle.isNotEmpty)
                      Text(
                        entry.subtitle,
                        style: context.txt.caption,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: Center(
        child: Text(t.commandPalette.empty, style: context.txt.muted),
      ),
    );
  }
}
