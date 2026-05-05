import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'section_title.dart';

class AiSuggestionCard extends StatelessWidget {
  const AiSuggestionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SectionTitle(title: 'AI Suggestion', actionText: 'See All'),
        const SizedBox(height: 12),
        Container(
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFB923C), Color(0xFFEA580C)],
            ),
            image: const DecorationImage(
              image: NetworkImage('https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=800&q=80'),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(Colors.black26, BlendMode.darken),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(8)),
                child: Text('Yoga & Meditation', style: AppTheme.semiboldStyle.copyWith(color: Colors.white, fontSize: 12)),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Metaverse\nYoga Training', style: AppTheme.headlineStyle.copyWith(color: Colors.white, fontSize: 22, height: 1.1)),
                  const SizedBox(height: 4),
                  Text('Brenda Lee Sensei', style: AppTheme.bodyStyle.copyWith(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 12),
                  Row(
                    children:  [
                      Icon(Icons.access_time, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text('25min', style: AppTheme.semiboldStyle.copyWith(color: Colors.white, fontSize: 12)),
                      SizedBox(width: 16),
                      Icon(Icons.local_fire_department, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text('578kcal', style: AppTheme.semiboldStyle.copyWith(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
