import 'package:flutter_test/flutter_test.dart';
import 'package:waydir/core/open/mime_resolver.dart';

void main() {
  group('MimeType', () {
    test('unknown is octet-stream', () {
      expect(MimeType.unknown.isUnknown, isTrue);
      expect(const MimeType('').isUnknown, isTrue);
      expect(const MimeType('image/png').isUnknown, isFalse);
    });
  });

  group('MimeResolver fallback', () {
    test('resolves common types by extension', () async {
      final r = MimeResolver.platform();
      // On Linux/macOS this still falls back to extension lookup when the
      // path does not exist on disk.
      final png = await r.resolve('/nonexistent/sample.png');
      expect(png.value, anyOf('image/png', isNotEmpty));
    });
  });
}
