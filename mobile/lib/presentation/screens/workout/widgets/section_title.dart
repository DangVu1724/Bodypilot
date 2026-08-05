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
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  title,
                  style: AppTheme.headlineStyle.copyWith(fontSize: 18),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(width: 4),
                Text(
                  subtitle!,
                  style: AppTheme.semiboldStyle.copyWith(fontSize: 16, color: Colors.grey),
                ),
              ]
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(actionText, style: AppTheme.semiboldStyle.copyWith(color: AppTheme.primary, fontSize: 14)),
      ],
    );
  }
}
