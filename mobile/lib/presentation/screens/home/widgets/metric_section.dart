import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';

class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final String chartType;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    required this.chartType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTheme.semiboldStyle.copyWith(color: Colors.white, fontSize: 13),
              ),
              Icon(icon, color: Colors.white, size: 20),
            ],
          ),
          const Spacer(),
          _buildMiniChart(chartType),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: AppTheme.headlineStyle.copyWith(color: Colors.white, fontSize: 24),
              ),
              const SizedBox(width: 2),
              Text(
                unit,
                style: AppTheme.bodyStyle.copyWith(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniChart(String type) {
    if (type == 'bar') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(5, (index) {
          final heights = [10.0, 25.0, 40.0, 30.0, 15.0];
          return Container(
            width: 8,
            height: heights[index],
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3 + (index * 0.1)),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      );
    } else if (type == 'line') {
      return Icon(Icons.show_chart, color: Colors.white.withOpacity(0.5), size: 50);
    } else {
      return Column(
        children: List.generate(
          4,
          (index) => Container(
            margin: const EdgeInsets.only(bottom: 4),
            width: 20,
            height: 6,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(3)),
          ),
        ),
      );
    }
  }
}

class MetricSection extends StatelessWidget {
  const MetricSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: const [
          MetricCard(
            title: 'Score',
            value: '88',
            unit: '%',
            icon: Icons.add,
            color: Color(0xFFF97316),
            chartType: 'bar',
          ),
          SizedBox(width: 16),
          MetricCard(
            title: 'Hydration',
            value: '781',
            unit: 'ml',
            icon: Icons.water_drop,
            color: Color(0xFF3B82F6),
            chartType: 'line',
          ),
          SizedBox(width: 16),
          MetricCard(
            title: 'Calories',
            value: '1,240',
            unit: 'kcal',
            icon: Icons.local_fire_department,
            color: Color(0xFF64748B),
            chartType: 'dots',
          ),
        ],
      ),
    );
  }
}
