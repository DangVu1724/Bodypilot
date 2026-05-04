import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'section_title.dart';

class FeaturedCard extends StatelessWidget {
  const FeaturedCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SectionTitle(title: 'Featured', actionText: 'See All'),
        const SizedBox(height: 12),
        Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            image: const DecorationImage(
              image: NetworkImage('https://images.unsplash.com/photo-1518611012118-696072aa579a?w=800&q=80'),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black.withOpacity(0.8), Colors.transparent],
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(8)),
                      child: const Text('Endurance', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                    Row(
                      children: const [
                        Icon(Icons.share, color: Colors.white, size: 20),
                        SizedBox(width: 12),
                        Icon(Icons.favorite, color: Colors.white, size: 20),
                      ],
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Body Circuit', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Row(
                          children: const [
                            Icon(Icons.access_time, color: Colors.blue, size: 14),
                            SizedBox(width: 4),
                            Text('50min', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            SizedBox(width: 12),
                            Icon(Icons.local_fire_department, color: Colors.orange, size: 14),
                            SizedBox(width: 4),
                            Text('251kcal', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            SizedBox(width: 12),
                            Icon(Icons.fitness_center, color: Colors.white70, size: 14),
                            SizedBox(width: 4),
                            Text('Upper Body', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                      child: const Icon(Icons.play_arrow, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
