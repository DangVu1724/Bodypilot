import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:core_shared/models/workout_session_model.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/data/services/push_notification_service.dart';

class WorkoutSummaryScreen extends StatelessWidget {
  final WorkoutSessionModel session;
  final int totalDurationSeconds;
  final double totalCaloriesBurned;
  final int completedSetsCount;
  final int totalSetsCount;

  const WorkoutSummaryScreen({
    super.key,
    required this.session,
    required this.totalDurationSeconds,
    required this.totalCaloriesBurned,
    required this.completedSetsCount,
    required this.totalSetsCount,
  });

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    if (mins == 0) return '${secs}s';
    return '${mins}m ${secs}s';
  }

  @override
  Widget build(BuildContext context) {
    final completionRate = totalSetsCount > 0 ? (completedSetsCount / totalSetsCount * 100).round() : 100;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark slate background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              const Spacer(),

              // Trophy / Success Banner Icon
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF97316), Color(0xFFFB923C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF97316).withValues(alpha: 0.4),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: Colors.white,
                  size: 56,
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Chúc Mừng! 🎉',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Bạn đã hoàn thành buổi tập "${session.name}"',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 36),

              // Summary Stats Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCol(
                      icon: Icons.timer_outlined,
                      value: _formatDuration(totalDurationSeconds),
                      label: 'Thời gian',
                      color: const Color(0xFF38BDF8),
                    ),
                    Container(width: 1, height: 40, color: Colors.white10),
                    _buildStatCol(
                      icon: Icons.local_fire_department_rounded,
                      value: '${totalCaloriesBurned.round()} kcal',
                      label: 'Calo tiêu thụ',
                      color: const Color(0xFFF97316),
                    ),
                    Container(width: 1, height: 40, color: Colors.white10),
                    _buildStatCol(
                      icon: Icons.check_circle_outline_rounded,
                      value: '$completionRate%',
                      label: 'Hoàn thành',
                      color: const Color(0xFF10B981),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Detailed Sets Info Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.fitness_center_rounded, color: Color(0xFF94A3B8), size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tổng số Hiệp (Sets) đã hoàn thành',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$completedSetsCount / $totalSetsCount Sets',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Save & Return Button
              ElevatedButton(
                onPressed: () async {
                  // Trigger workout completed local notification
                  await PushNotificationService.showWorkoutCompletedNotification(
                    title: 'Đã lưu buổi tập ${session.name}! 🎉💪',
                    totalCaloriesBurned: totalCaloriesBurned,
                  );

                  // Complete & navigate back
                  if (context.mounted) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  minimumSize: const Size(double.infinity, 58),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 4,
                ),
                child: Text(
                  'Hoàn Thành & Lưu Nhật Ký',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCol({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
