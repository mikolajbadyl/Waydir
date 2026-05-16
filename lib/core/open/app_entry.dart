/// A launchable application that can open files.
///
/// [id] is the platform-stable identifier used for persistence and for
/// setting the default handler:
///  - Linux: the desktop file id (e.g. `org.gnome.eog.desktop`)
///  - macOS: the bundle path (e.g. `/Applications/Preview.app`)
///  - Windows: the ProgId or executable path
class AppEntry {
  final String id;
  final String name;

  /// Raw launch command/template. Platform resolvers know how to run it;
  /// callers should go through the resolver's `launch`, not exec this directly.
  final String exec;

  /// Best-effort path to an icon file for display. May be null.
  final String? iconPath;

  /// True when this is the system default handler for the file's type.
  final bool isDefault;

  const AppEntry({
    required this.id,
    required this.name,
    required this.exec,
    this.iconPath,
    this.isDefault = false,
  });

  /// Sentinel id for "whatever the OS would do" — opening this entry routes
  /// through the system shell-open instead of launching a specific binary.
  static const systemDefaultId = '__waydir_system_default__';

  factory AppEntry.systemDefault(String name) => AppEntry(
    id: systemDefaultId,
    name: name,
    exec: systemDefaultId,
    isDefault: true,
  );

  bool get isSystemDefault => id == systemDefaultId;

  AppEntry copyWith({bool? isDefault}) => AppEntry(
    id: id,
    name: name,
    exec: exec,
    iconPath: iconPath,
    isDefault: isDefault ?? this.isDefault,
  );

  @override
  bool operator ==(Object other) =>
      other is AppEntry && other.id == id && other.exec == exec;

  @override
  int get hashCode => Object.hash(id, exec);
}
