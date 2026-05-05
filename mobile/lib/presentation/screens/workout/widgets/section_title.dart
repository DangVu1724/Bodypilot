import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String actionText;

  const SectionTitle({super.key, required this.title, this.subtitle, required this.actionText});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          children: [
            Text(title, style: AppTheme.headlineStyle.copyWith(fontSize: 18)),
            if (subtitle != null) ...[
              const SizedBox(width: 4),
              Text(subtitle!, style: AppTheme.semiboldStyle.copyWith(fontSize: 16, color: Colors.grey)),
            ]
          ],
        ),
        Text(actionText, style: AppTheme.semiboldStyle.copyWith(color: AppTheme.primary, fontSize: 14)),
      ],
    );
  }
}
