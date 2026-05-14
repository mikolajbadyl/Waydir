import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import '../../../core/settings/settings_registry.dart';
import '../../../i18n/strings.g.dart';
import '../preferences_view.dart';

class GeneralPane extends StatelessWidget {
  const GeneralPane({super.key});

  @override
  Widget build(BuildContext context) {
    final registry = SettingsRegistry.instance;
    final restoreSession = registry.byId('general.restoreSession');
    final defaultPath = registry.byId('general.defaultStartingPath');
    final confirmDelete = registry.byId('general.confirmDelete');
    final terminal = registry.byId('general.terminal');
    final terminalCustom = registry.byId('general.terminalCustomCommand');

    return SettingsPaneScaffold(
      children: [
        SettingsSection(
          title: t.preferences.general.startupSection,
          children: [
            RegistrySettingRow(setting: restoreSession),
            RegistrySettingRow(setting: defaultPath),
          ],
        ),
        SettingsSection(
          title: t.preferences.general.fileOpsSection,
          children: [RegistrySettingRow(setting: confirmDelete)],
        ),
        SettingsSection(
          title: t.preferences.general.terminalSection,
          children: [
            RegistrySettingRow(setting: terminal),
            Watch((_) {
              if (terminal.value != 'custom') return const SizedBox.shrink();
              return RegistrySettingRow(setting: terminalCustom);
            }),
          ],
        ),
      ],
    );
  }
}
