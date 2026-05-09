import 'package:flutter/material.dart';
import 'app_text_styles.dart';

class AppColors {
  static const bg = Color(0xFF181818);
  static const bgSurface = Color(0xFF1E1E1E);
  static const bgSidebar = Color(0xFF121212);
  static const bgToolbar = Color(0xFF121212);
  static const bgStatus = Color(0xFF121212);
  static const bgHover = Color(0xFF2A2D31);
  static const bgSelected = Color(0xFF2A2D31);
  static const bgSelectedMuted = Color(0xFF2A2D31);
  static const bgInput = Color(0xFF2A2D31);
  static const bgDivider = Color(0xFF3A3A3A);
  static const borderColor = Color(0xFF3A3A3A);

  static const accent = Color(0xFF5CA8FF);
  static const accentHover = Color(0xFF7CBCFF);

  static const fg = Color(0xFFE4E4E4);
  static const fgMuted = Color(0xFF9CA3AF);
  static const fgSubtle = Color(0xFF4A4A4A);
  static const fgAccent = Color(0xFF7CBCFF);

  static const danger = Color(0xFFCF6679);

  static Color get folderColor => accent;
}

class AppTheme {
  static const _systemFont = 'system-ui';

  static ThemeData build() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        surface: AppColors.bgSurface,
        onSurface: AppColors.fg,
      ),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      splashFactory: NoSplash.splashFactory,
      hoverColor: AppColors.bgHover.withValues(alpha: 0.5),
      dividerColor: AppColors.bgDivider,
      iconTheme: const IconThemeData(color: AppColors.fgMuted, size: 20),
      textTheme: Typography.whiteCupertino.copyWith(
        bodyLarge: TextStyle(
          fontSize: 15,
          height: 1.4,
          color: AppColors.fg,
          fontFamily: _systemFont,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.35,
          color: AppColors.fg,
          fontFamily: _systemFont,
        ),
        bodySmall: TextStyle(
          fontSize: 13,
          height: 1.3,
          color: AppColors.fgMuted,
          fontFamily: _systemFont,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
          color: AppColors.fg,
          fontFamily: _systemFont,
        ),
        labelSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: AppColors.fgMuted,
          fontFamily: _systemFont,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.fg,
          fontFamily: _systemFont,
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(AppColors.fgSubtle),
        radius: const Radius.circular(4),
        thickness: WidgetStateProperty.all(6),
        thumbVisibility: WidgetStateProperty.all(false),
      ),
      extensions: [AppTextStyles.dark],
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          border: Border.all(color: AppColors.borderColor),
          borderRadius: BorderRadius.circular(4),
        ),
        textStyle: TextStyle(
          fontSize: 13,
          color: AppColors.fg,
          fontFamily: _systemFont,
        ),
        waitDuration: const Duration(milliseconds: 600),
      ),
    );
  }
}
