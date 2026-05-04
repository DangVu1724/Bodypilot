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
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (subtitle != null) ...[
              const SizedBox(width: 4),
              Text(subtitle!, style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500)),
            ]
          ],
        ),
        Text(actionText, style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600, fontSize: 14)),
      ],
    );
  }
}
