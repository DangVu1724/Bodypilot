import 'package:core_shared/core_shared.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/theme/app_theme.dart';

/// Widget hiển thị thẻ bài tập trong gợi ý lịch tập AI
class WorkoutDayCard extends StatelessWidget {
  final DailyWorkoutItemModel item;

  const WorkoutDayCard({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFFF7A30).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.fitness_center_rounded,
                color: Color(0xFFFF7A30),
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.exerciseNameSnapshot.isNotEmpty
                        ? item.exerciseNameSnapshot
                        : (item.notes != null && item.notes!.isNotEmpty ? item.notes! : 'Bài tập tự do'),
                    style: GoogleFonts.workSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _buildParamString(item),
                    style: AppTheme.bodyStyle.copyWith(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.local_fire_department, color: Colors.orange, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${item.caloriesBurnedSnapshot.toStringAsFixed(0)} kcal',
                        style: GoogleFonts.workSans(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF475569),
                        ),
                      ),
                      if (item.notes != null && item.notes!.isNotEmpty) ...[
                        const SizedBox(width: 16),
                        const Icon(Icons.description_outlined, color: Colors.blue, size: 14),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.notes!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.bodyStyle.copyWith(fontSize: 12, color: Colors.blue),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildParamString(DailyWorkoutItemModel item) {
    final sb = StringBuffer();
    if (item.setsSnapshot != null && item.setsSnapshot! > 0) {
      sb.write('${item.setsSnapshot} hiệp');
    }
    if (item.repsSnapshot != null && item.repsSnapshot! > 0) {
      if (sb.isNotEmpty) sb.write(' • ');
      sb.write('${item.repsSnapshot} lần');
    }
    if (item.weightKgSnapshot != null && item.weightKgSnapshot! > 0) {
      if (sb.isNotEmpty) sb.write(' • ');
      sb.write('${item.weightKgSnapshot}kg');
    }
    if (item.durationMinutesSnapshot != null && item.durationMinutesSnapshot! > 0) {
      if (sb.isNotEmpty) sb.write(' • ');
      sb.write('${item.durationMinutesSnapshot} phút');
    }
    if (item.distanceKmSnapshot != null && item.distanceKmSnapshot! > 0) {
      if (sb.isNotEmpty) sb.write(' • ');
      sb.write('${item.distanceKmSnapshot}km');
    }
    return sb.toString();
  }
}
