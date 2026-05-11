class Drive {
  final String id;
  final String label;
  final String? mountPoint;
  final bool isRemovable;
  final String? fsType;

  const Drive({
    required this.id,
    required this.label,
    this.mountPoint,
    required this.isRemovable,
    this.fsType,
  });

  bool get isMounted => mountPoint != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Drive &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          label == other.label &&
          mountPoint == other.mountPoint &&
          isRemovable == other.isRemovable &&
          fsType == other.fsType;

  @override
  int get hashCode =>
      id.hashCode ^
      label.hashCode ^
      mountPoint.hashCode ^
      isRemovable.hashCode ^
      fsType.hashCode;
}
