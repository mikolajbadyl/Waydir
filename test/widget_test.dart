import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:waydir/ui/theme/app_theme.dart';

void main() {
  test('AppTheme.build creates valid ThemeData', () {
    final theme = AppTheme.build();
    expect(theme.brightness, Brightness.dark);
    expect(theme.splashFactory, NoSplash.splashFactory);
    expect(theme.scaffoldBackgroundColor, AppColors.bg);
  });
}
