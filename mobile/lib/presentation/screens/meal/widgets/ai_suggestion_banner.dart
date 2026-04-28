import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';

class AiSuggestionBanner extends StatelessWidget {
  const AiSuggestionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'AI Suggestion',
              style: AppTheme.semiboldStyle.copyWith(fontSize: 16),
            ),
            Text(
              'See All',
              style: AppTheme.semiboldStyle.copyWith(fontSize: 13, color: const Color(0xFFF07025)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B), // Dark blue/slate color
            borderRadius: BorderRadius.circular(24),
            image: const DecorationImage(
              image: AssetImage('assets/images/fruit.png'), // Add an abstract or dark texture here if available
              fit: BoxFit.cover,
              opacity: 0.3,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Smart Diet',
                  style: AppTheme.semiboldStyle.copyWith(color: Colors.white, fontSize: 10),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Tạo chế độ ăn uống\ntrong tuần theo AI',
                style: AppTheme.headlineStyle.copyWith(
                  color: Colors.white,
                  fontSize: 20,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implement AI diet generation
                },
                icon: const Icon(Icons.auto_awesome, size: 16),
                label: const Text('Tạo ngay'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1E293B),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
