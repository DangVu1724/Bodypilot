import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';

class HeroProfileAvatar extends StatelessWidget {
  final String? avatarUrl;
  final double radius;
  final String heroTag;
  final VoidCallback? onTap;
  final Border? border;

  const HeroProfileAvatar({
    super.key,
    this.avatarUrl,
    this.radius = 24,
    this.heroTag = 'profile_avatar',
    this.onTap,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Hero(
        tag: heroTag,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: border ?? Border.all(color: Colors.white.withOpacity(0.2), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: radius,
            backgroundColor: AppTheme.surface,
            backgroundImage: (avatarUrl != null && avatarUrl!.isNotEmpty)
                ? NetworkImage(avatarUrl!)
                : const AssetImage('assets/images/man.png') as ImageProvider,
            onBackgroundImageError: (exception, stackTrace) {
              // Fallback if image fails to load
            },
          ),
        ),
      ),
    );
  }
}
