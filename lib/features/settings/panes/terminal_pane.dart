import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:signals/signals_flutter.dart';

import '../../../core/settings/settings_store.dart';
import '../../../core/terminal/terminal.dart';
import '../../../i18n/strings.g.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/theme/app_text_styles.dart';
import '../../../ui/widgets/app_dropdown.dart';

class TerminalPane extends StatefulWidget {
  const TerminalPane({super.key});

  @override
  State<TerminalPane> createState() => _TerminalPaneState();
}

class _TerminalPaneState extends State<TerminalPane> {
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
