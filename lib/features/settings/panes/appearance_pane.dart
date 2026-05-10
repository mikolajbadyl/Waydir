import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:signals/signals_flutter.dart';

import '../../../core/settings/settings_store.dart';
import '../../../i18n/strings.g.dart';
import '../../../ui/theme/app_text_styles.dart';
import '../../../ui/widgets/app_dropdown.dart';

class AppearancePane extends StatefulWidget {
  const AppearancePane({super.key});

  @override
  State<AppearancePane> createState() => _AppearancePaneState();
}

class _AppearancePaneState extends State<AppearancePane> {
  List<AppDropdownItem<double>> _items() {
    final t = context.t;
    return [
      AppDropdownItem(
        value: 0,
        label: t.preferences.appearance.scaleAuto,
        icon: PhosphorIconsRegular.magicWand,
      ),
      AppDropdownItem(value: 0.5, label: t.preferences.appearance.scale50),
      AppDropdownItem(value: 0.75, label: t.preferences.appearance.scale75),
      AppDropdownItem(value: 1.0, label: t.preferences.appearance.scale100),
      AppDropdownItem(value: 1.25, label: t.preferences.appearance.scale125),
      AppDropdownItem(value: 1.5, label: t.preferences.appearance.scale150),
      AppDropdownItem(value: 1.75, label: t.preferences.appearance.scale175),
      AppDropdownItem(value: 2.0, label: t.preferences.appearance.scale200),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.preferences.appearance.title, style: context.txt.pageTitle),
          const SizedBox(height: 4),
          Text(t.preferences.appearance.subtitle, style: context.txt.muted),
          const SizedBox(height: 20),
          Text(
            t.preferences.appearance.scaleLabel,
            style: context.txt.fieldLabel,
          ),
          const SizedBox(height: 8),
          Watch((context) {
            final current = SettingsStore.instance.uiScale.value;
            final items = _items();
            final values = items.map((e) => e.value).toSet();
            final value = values.contains(current) ? current : 0.0;
            return SizedBox(
              width: 360,
              child: AppDropdown<double>(
                value: value,
                items: items,
                onChanged: (v) {
                  SettingsStore.instance.uiScale.value = v;
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}
