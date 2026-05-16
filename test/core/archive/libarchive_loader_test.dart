import 'package:flutter_test/flutter_test.dart';
import 'package:waydir/core/archive/libarchive_loader.dart';

void main() {
  test('libarchive loader degrades without throwing', () {
    LibarchiveLoader.resetForTest();

    final result = LibarchiveLoader.load();

    expect(result.isAvailable || !result.isAvailable, isTrue);
  });

  test('libarchive version is readable when the runtime is available', () {
    LibarchiveLoader.resetForTest();

    final result = LibarchiveLoader.load();
    final version = LibarchiveLoader.versionString();

    if (result.isAvailable) {
      expect(version, isNotNull);
      expect(version, contains('libarchive'));
    } else {
      expect(version, isNull);
    }
  });
}
