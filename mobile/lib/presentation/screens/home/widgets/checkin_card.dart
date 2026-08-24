import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/data/services/token_service.dart';
import 'package:mobile/presentation/bloc/checkin/checkin_cubit.dart';
import 'package:mobile/presentation/bloc/checkin/checkin_state.dart';
import 'package:mobile/presentation/screens/checkin/meal_check_in_sheet.dart';
import 'package:mobile/presentation/screens/checkin/workout_check_in_sheet.dart';
import 'package:mobile/presentation/screens/checkin/meal_summary_sheet.dart';
import 'package:mobile/presentation/screens/checkin/workout_summary_sheet.dart';

class CheckInCard extends StatelessWidget {
  const CheckInCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CheckInCubit, CheckInState>(
      builder: (context, state) {
        final status = (state is CheckInStatusLoaded)
            ? state.status
            : context.read<CheckInCubit>().lastStatus;

        if (status != null) {
          if (status.onboardingNeeded) {
            return Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF6366F1), // Indigo
                    Color(0xFF8B5CF6), // Purple
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), shape: BoxShape.circle),
                    child: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Khởi tạo Lộ trình cùng AI',
                          style: AppTheme.headlineStyle.copyWith(color: Colors.white, fontSize: 16.5),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Hãy ghi lại các bữa ăn và bài tập đầu tiên để BodyPilot bắt đầu theo dõi tiến độ cho bạn nhé!',
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.92),
                            fontSize: 12.5,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          final isMealDone = TokenService.isMealCheckInDone();
          final isWorkoutDone = TokenService.isWorkoutCheckInDone();

          return Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: (isMealDone && isWorkoutDone)
                    ? [const Color(0xFF0D9488), const Color(0xFF14B8A6)]
                    : [const Color(0xFFFF7E5F), const Color(0xFFFEB47B)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: ((isMealDone && isWorkoutDone) ? const Color(0xFF0D9488) : const Color(0xFFFF7E5F)).withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), shape: BoxShape.circle),
                      child: Icon(
                        (isMealDone && isWorkoutDone) ? Icons.task_alt_rounded : Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (isMealDone && isWorkoutDone)
                                ? 'Đã Tổng Kết Check-in Tuần'
                                : 'Check-in Chủ Nhật Hàng Tuần',
                            style: AppTheme.headlineStyle.copyWith(color: Colors.white, fontSize: 17),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            (isMealDone && isWorkoutDone)
                                ? 'Bấm vào từng mục bên dưới để xem lại thông số & đánh giá từ AI!'
                                : 'Tổng kết & Cập nhật chỉ số để AI tối ưu kế hoạch tuần tới cho bạn!',
                            style: GoogleFonts.inter(
                              color: Colors.white.withValues(alpha: 0.92),
                              fontSize: 12.5,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (isMealDone) {
                            showModalBottomSheet(
                              context: context,
                              useRootNavigator: true,
                              isScrollControlled: true,
                              backgroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                              ),
                              builder: (_) => MealSummarySheet(
                                summaryData: TokenService.getMealCheckInSummary(),
                              ),
                            );
                          } else {
                            showModalBottomSheet(
                              context: context,
                              useRootNavigator: true,
                              isScrollControlled: true,
                              backgroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                              ),
                              builder: (_) => MealCheckInSheet(
                                currentWeight: status.currentWeight,
                                currentGoal: status.currentGoal,
                              ),
                            );
                          }
                        },
                        icon: Icon(
                          isMealDone ? Icons.check_circle_rounded : Icons.restaurant_menu_rounded,
                          size: 18,
                          color: isMealDone ? const Color(0xFF059669) : const Color(0xFFD97706),
                        ),
                        label: Text(
                          isMealDone ? 'Đã tổng kết' : 'Dinh Dưỡng',
                          style: AppTheme.headlineStyle.copyWith(
                            fontSize: 13,
                            color: isMealDone ? const Color(0xFF047857) : const Color(0xFFD97706),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isMealDone ? const Color(0xFFECFDF5) : Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (isWorkoutDone) {
                            showModalBottomSheet(
                              context: context,
                              useRootNavigator: true,
                              isScrollControlled: true,
                              backgroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                              ),
                              builder: (_) => WorkoutSummarySheet(
                                summaryData: TokenService.getWorkoutCheckInSummary(),
                              ),
                            );
                          } else {
                            showModalBottomSheet(
                              context: context,
                              useRootNavigator: true,
                              isScrollControlled: true,
                              backgroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                              ),
                              builder: (_) => const WorkoutCheckInSheet(),
                            );
                          }
                        },
                        icon: Icon(
                          isWorkoutDone ? Icons.check_circle_rounded : Icons.fitness_center_rounded,
                          size: 18,
                          color: isWorkoutDone ? const Color(0xFF059669) : const Color(0xFF2563EB),
                        ),
                        label: Text(
                          isWorkoutDone ? 'Đã tổng kết' : 'Luyện Tập',
                          style: AppTheme.headlineStyle.copyWith(
                            fontSize: 13,
                            color: isWorkoutDone ? const Color(0xFF047857) : const Color(0xFF2563EB),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isWorkoutDone ? const Color(0xFFECFDF5) : Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
