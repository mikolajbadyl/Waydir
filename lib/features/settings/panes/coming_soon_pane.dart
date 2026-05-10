import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../i18n/strings.g.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/theme/app_text_styles.dart';
import '../preferences_view.dart';

class ComingSoonPane extends StatelessWidget {
  final CategoryMeta meta;
  const ComingSoonPane({required this.meta, super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PhosphorIcon(meta.icon, size: 36, color: AppColors.fgSubtle),
          const SizedBox(height: 12),
          Text(
            meta.label(),
            style: context.txt.dialogTitle.copyWith(
              color: AppColors.fgMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            t.preferences.comingSoon,
            style: context.txt.muted.copyWith(color: AppColors.fgSubtle),
          ),
        ],
      ),
    );
  }
}
