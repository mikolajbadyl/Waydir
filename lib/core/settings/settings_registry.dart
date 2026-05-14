import 'package:flutter/widgets.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:signals/signals.dart';

import '../../i18n/strings.g.dart';
import 'settings_store.dart';

enum SettingsCategory { general, appearance }

enum SettingKind { toggle, choice, text }

class SettingChoice<T> {
  final T value;
  final String Function() label;
  final IconData icon;

  const SettingChoice({
    required this.value,
    required this.label,
    required this.icon,
  });
}

abstract class AppSetting<T> {
  final String id;
  final SettingsCategory category;
  final SettingKind kind;
  final String Function() label;
  final String? Function()? hint;
  final List<String> searchTerms;
  final Signal<T> signal;

  const AppSetting({
    required this.id,
    required this.category,
    required this.kind,
    required this.label,
    this.hint,
    this.searchTerms = const [],
    required this.signal,
  });

  T get value => signal.value;

  set value(T next) => signal.value = next;

  String displayValue();
}

class ToggleSetting extends AppSetting<bool> {
  const ToggleSetting({
    required super.id,
    required super.category,
    required super.label,
    super.hint,
    super.searchTerms,
    required super.signal,
  }) : super(kind: SettingKind.toggle);

  void toggle() => value = !value;

  @override
  String displayValue() => value ? 'On' : 'Off';
}

class ChoiceSetting<T> extends AppSetting<T> {
  final List<SettingChoice<T>> choices;

  const ChoiceSetting({
    required super.id,
    required super.category,
    required super.label,
    super.hint,
    super.searchTerms,
    required super.signal,
    required this.choices,
  }) : super(kind: SettingKind.choice);

  SettingChoice<T> choiceFor(T value) {
    return choices.firstWhere(
      (choice) => choice.value == value,
      orElse: () => choices.first,
    );
  }

  @override
  String displayValue() => choiceFor(value).label();
}

class TextSetting extends AppSetting<String> {
  final String hintText;

  const TextSetting({
    required super.id,
    required super.category,
    required super.label,
    super.hint,
    super.searchTerms,
    required super.signal,
    this.hintText = '',
  }) : super(kind: SettingKind.text);

  @override
  String displayValue() => value.isEmpty ? hintText : value;
}

class SettingsRegistry {
  SettingsRegistry._();

  static final SettingsRegistry instance = SettingsRegistry._();

  late final List<AppSetting<dynamic>> all = [
    ToggleSetting(
      id: 'general.restoreSession',
      category: SettingsCategory.general,
      label: () => t.preferences.general.restoreSession,
      hint: () => t.preferences.general.restoreSessionHint,
      searchTerms: const ['startup', 'tabs', 'panes'],
      signal: SettingsStore.instance.restoreSession,
    ),
    TextSetting(
      id: 'general.defaultStartingPath',
      category: SettingsCategory.general,
      label: () => t.preferences.general.defaultPath,
      hint: () => t.preferences.general.defaultPathHint,
      hintText: '/home/user',
      searchTerms: const ['startup', 'home', 'path'],
      signal: SettingsStore.instance.defaultStartingPath,
    ),
    ToggleSetting(
      id: 'general.confirmDelete',
      category: SettingsCategory.general,
      label: () => t.preferences.general.confirmDelete,
      hint: () => t.preferences.general.confirmDeleteHint,
      searchTerms: const ['delete', 'file operations'],
      signal: SettingsStore.instance.confirmDelete,
    ),
    ChoiceSetting<String>(
      id: 'general.terminal',
      category: SettingsCategory.general,
      label: () => t.preferences.general.terminalLabel,
      hint: () => t.preferences.general.terminalHint,
      searchTerms: const ['terminal', 'open in terminal'],
      signal: SettingsStore.instance.terminal,
      choices: [
        SettingChoice(
          value: 'auto',
          label: () => t.preferences.general.terminalAuto,
          icon: PhosphorIconsRegular.magicWand,
        ),
        SettingChoice(
          value: 'custom',
          label: () => t.preferences.general.terminalCustom,
          icon: PhosphorIconsRegular.code,
        ),
      ],
    ),
    TextSetting(
      id: 'general.terminalCustomCommand',
      category: SettingsCategory.general,
      label: () => t.preferences.general.terminalCustomLabel,
      hint: () => t.preferences.general.terminalCustomHelp,
      hintText: t.preferences.general.terminalCustomHint,
      searchTerms: const ['terminal', 'command'],
      signal: SettingsStore.instance.terminalCustomCommand,
    ),
    ToggleSetting(
      id: 'appearance.showHiddenDefault',
      category: SettingsCategory.appearance,
      label: () => t.preferences.appearance.showHidden,
      hint: () => t.preferences.appearance.showHiddenHint,
      searchTerms: const ['hidden', 'dotfiles', 'files'],
      signal: SettingsStore.instance.showHiddenDefault,
    ),
    ChoiceSetting<String>(
      id: 'appearance.rowDensity',
      category: SettingsCategory.appearance,
      label: () => t.preferences.appearance.rowDensity,
      searchTerms: const ['rows', 'density', 'compact', 'comfortable'],
      signal: SettingsStore.instance.rowDensity,
      choices: [
        SettingChoice(
          value: 'comfortable',
          label: () => t.preferences.appearance.rowDensityComfortable,
          icon: PhosphorIconsRegular.rows,
        ),
        SettingChoice(
          value: 'compact',
          label: () => t.preferences.appearance.rowDensityCompact,
          icon: PhosphorIconsRegular.list,
        ),
      ],
    ),
    ChoiceSetting<String>(
      id: 'appearance.dateFormat',
      category: SettingsCategory.appearance,
      label: () => t.preferences.appearance.dateFormat,
      searchTerms: const ['date', 'time', 'modified', 'relative', 'iso'],
      signal: SettingsStore.instance.dateFormat,
      choices: [
        SettingChoice(
          value: 'iso',
          label: () => t.preferences.appearance.dateFormatIso,
          icon: PhosphorIconsRegular.calendar,
        ),
        SettingChoice(
          value: 'locale',
          label: () => t.preferences.appearance.dateFormatLocale,
          icon: PhosphorIconsRegular.calendarBlank,
        ),
        SettingChoice(
          value: 'relative',
          label: () => t.preferences.appearance.dateFormatRelative,
          icon: PhosphorIconsRegular.clockClockwise,
        ),
      ],
    ),
    ToggleSetting(
      id: 'appearance.recentDatesRelative',
      category: SettingsCategory.appearance,
      label: () => t.preferences.appearance.recentDatesRelative,
      hint: () => t.preferences.appearance.recentDatesRelativeHint,
      searchTerms: const ['date', 'time', 'recent', 'relative'],
      signal: SettingsStore.instance.recentDatesRelative,
    ),
  ];

  List<AppSetting<dynamic>> byCategory(SettingsCategory category) {
    return all.where((setting) => setting.category == category).toList();
  }

  AppSetting<dynamic> byId(String id) {
    return all.firstWhere((setting) => setting.id == id);
  }
}
