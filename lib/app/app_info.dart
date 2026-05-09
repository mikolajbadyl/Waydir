class AppInfo {
  static const String name = 'Waydir';
  static const String tagline = 'Navigate your files. Your way.';
  static const String description =
      'A fast, keyboard-driven desktop file manager built with Flutter.';
  static const String version = '0.1.0';
  static const int buildNumber = 1;
  static const String homepage = 'https://github.com/mikolajbadyl/waydir';
  static const String license = 'MIT';

  static String get versionLabel => 'v$version';
  static String get fullVersion => '$version+$buildNumber';

  const AppInfo._();
}
