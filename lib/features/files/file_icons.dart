import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../ui/theme/app_theme.dart';

Color fileIconColor(String ext) {
  return switch (ext) {
    'dart' => AppColors.fileCode,
    'py' => AppColors.fileCode,
    'js' || 'ts' => AppColors.fileJs,
    'html' => AppColors.fileHtml,
    'css' => AppColors.fileCss,
    'json' => AppColors.fgMuted,
    'md' => AppColors.accentHover,
    'png' || 'jpg' || 'jpeg' || 'gif' || 'svg' || 'webp' => AppColors.fileImage,
    'zip' || 'tar' || 'gz' || 'rar' || '7z' => AppColors.fileArchive,
    'pdf' => AppColors.danger,
    'mp3' || 'wav' || 'flac' || 'ogg' => AppColors.fileAudio,
    'mp4' || 'avi' || 'mkv' || 'mov' => AppColors.fileVideo,
    'txt' || 'log' => AppColors.fgMuted,
    _ => AppColors.fileDefault,
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
    'png' ||
    'jpg' ||
    'jpeg' ||
    'gif' ||
    'svg' ||
    'webp' => PhosphorIconsRegular.fileImage,
    'zip' || 'tar' || 'gz' || 'rar' || '7z' => PhosphorIconsRegular.fileZip,
    'pdf' => PhosphorIconsRegular.filePdf,
    'mp3' || 'wav' || 'flac' || 'ogg' => PhosphorIconsRegular.fileAudio,
    'mp4' || 'avi' || 'mkv' || 'mov' => PhosphorIconsRegular.fileVideo,
    'txt' || 'log' => PhosphorIconsRegular.fileTxt,
    _ => PhosphorIconsRegular.file,
  };
}
