import 'package:package_info_plus/package_info_plus.dart';
import 'package:signals/signals.dart';

class AppInfo {
  static const String name = 'Waydir';
  static const String tagline = 'Navigate your files. Your way.';
  static const String description =
      'A fast, keyboard-driven desktop file manager built with Flutter.';
  static const String homepage = 'https://github.com/mikolajbadyl/waydir';
  static const String license = 'MIT';

  static final version = signal<String>('…');
  static final Computed<String> versionLabel = computed(
    () => 'v${version.value}',
  );

  static Future<void> init() async {
    final info = await PackageInfo.fromPlatform();
    version.value = info.version;
  }

  const AppInfo._();
}
