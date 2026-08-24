import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const SectionHeader({
    super.key,
    required this.title,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTheme.semiboldStyle.copyWith(fontSize: 18),
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            child: Text(
              'Xem tất cả',
              style: AppTheme.semiboldStyle.copyWith(color: AppTheme.primary, fontSize: 13),
            ),
          ),
      ],
    );
  }
}
