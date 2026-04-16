import 'package:flutter/material.dart';

class BlackButton extends StatelessWidget {
  const BlackButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.textColor = Colors.white,
    this.backgroundColor = Colors.black,
    this.borderRadius = 16,
    this.padding = const EdgeInsets.symmetric(vertical: 16),
    this.icon,
  });

  final String label;
  final Future<void> Function()? onPressed;
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
                style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          )
        : Text(
            label,
            style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600),
          );

    return ElevatedButton(
      onPressed: onPressed != null
          ? () async {
              await onPressed!();
            }
          : null,
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
