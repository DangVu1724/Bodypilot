// black_button.dart
import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';

class BlackButton2 extends StatelessWidget {
  const BlackButton2({
    super.key,
    required this.label,
    required this.onPressed, // Đổi thành VoidCallback
    this.textColor = Colors.white,
    this.backgroundColor = Colors.black,
    this.borderRadius = 16,
    this.padding = const EdgeInsets.symmetric(vertical: 16),
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed; // ← VoidCallback
  final Color textColor;
  final Color backgroundColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final child = icon != null
        ? Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon!,
              const SizedBox(width: 10),
              Text(
                label,
                style: AppTheme.semiboldStyle.copyWith(color: textColor, fontSize: 16),
              ),
            ],
          )
        : Text(
            label,
            style: AppTheme.semiboldStyle.copyWith(color: textColor, fontSize: 16),
          );

    return ElevatedButton(
      onPressed: onPressed, // Trực tiếp dùng VoidCallback
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        padding: padding,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
        elevation: 0,
      ),
      child: child,
    );
  }
}
