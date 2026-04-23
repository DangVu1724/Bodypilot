import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';

class WorkoutCard extends StatelessWidget {
  const WorkoutCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        image: const DecorationImage(image: AssetImage('assets/images/gym_workout.png'), fit: BoxFit.cover),
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildIconLabel(Icons.timer_outlined, '25min'),
                    const SizedBox(width: 12),
                    _buildIconLabel(Icons.local_fire_department_outlined, '412kcal'),
                  ],
                ),
                const Spacer(),
                Text(
                  'Upper Strength 2',
                  style: AppTheme.headlineStyle,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '8 Series Workout',
                      style: AppTheme.bodyStyle.copyWith(color: Colors.white.withOpacity(0.7)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Text(
                        'Intense',
                        style: AppTheme.semiboldStyle.copyWith(color: Colors.white, fontSize: 10),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                      child: const Icon(Icons.play_arrow, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconLabel(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.7), size: 16),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTheme.bodyStyle.copyWith(color: Colors.white.withOpacity(0.7), fontSize: 12),
        ),
      ],
    );
  }
}

class WorkoutSection extends StatelessWidget {
  const WorkoutSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const WorkoutCard();
  }
}
