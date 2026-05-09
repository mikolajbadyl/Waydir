import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

Color fileIconColor(String ext) {
  return switch (ext) {
    'dart' => const Color(0xFF5CA8FF),
    'py' => const Color(0xFF5CA8FF),
    'js' || 'ts' => const Color(0xFFF7DF1E),
    'html' => const Color(0xFFE34F26),
    'css' => const Color(0xFF1572B6),
    'json' => const Color(0xFF9CA3AF),
    'md' => const Color(0xFF7CBCFF),
    'png' || 'jpg' || 'jpeg' || 'gif' || 'svg' || 'webp' =>
      const Color(0xFFA6E3A1),
    'zip' || 'tar' || 'gz' || 'rar' || '7z' => const Color(0xFFFAB387),
    'pdf' => const Color(0xFFCF6679),
    'mp3' || 'wav' || 'flac' || 'ogg' => const Color(0xFFCBA6F7),
    'mp4' || 'avi' || 'mkv' || 'mov' => const Color(0xFFF5C2E7),
    'txt' || 'log' => const Color(0xFF9CA3AF),
    _ => const Color(0xFF6B6B6B),
  };
}

IconData fileIcon(String ext) {
  return switch (ext) {
    'dart' || 'py' => PhosphorIconsRegular.fileCode,
    'js' => PhosphorIconsRegular.fileJs,
    'ts' => PhosphorIconsRegular.fileTs,
    'html' || 'htm' => PhosphorIconsRegular.fileHtml,
    'css' => PhosphorIconsRegular.fileCss,
    'json' => PhosphorIconsRegular.fileCode,
    'md' => PhosphorIconsRegular.fileMd,
    'png' || 'jpg' || 'jpeg' || 'gif' || 'svg' || 'webp' =>
      PhosphorIconsRegular.fileImage,
    'zip' || 'tar' || 'gz' || 'rar' || '7z' => PhosphorIconsRegular.fileZip,
    'pdf' => PhosphorIconsRegular.filePdf,
    'mp3' || 'wav' || 'flac' || 'ogg' => PhosphorIconsRegular.fileAudio,
    'mp4' || 'avi' || 'mkv' || 'mov' => PhosphorIconsRegular.fileVideo,
    'txt' || 'log' => PhosphorIconsRegular.fileTxt,
    _ => PhosphorIconsRegular.file,
  };
}
