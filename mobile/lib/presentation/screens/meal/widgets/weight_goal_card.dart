import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/presentation/bloc/user/user_cubit.dart';
import 'package:mobile/presentation/bloc/user/user_state.dart';

class WeightGoalCard extends StatelessWidget {
  const WeightGoalCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserCubit, UserState>(
      builder: (context, state) {
        double currentWeight = 0.0;
        double targetWeight = 0.0;
        double startWeight = 0.0; // Nên có thêm startWeight để tính % chính xác

        if (state is UserLoaded) {
          currentWeight = state.user.metrics?.weight ?? 0.0;
          targetWeight = state.user.goal?.targetWeight ?? 0.0;
          startWeight = 80.0; // Mock dữ liệu cân nặng lúc mới bắt đầu
        }

        // Tính toán logic tiến độ thực tế
        double progress = 0.0;
        if (targetWeight > 0 && currentWeight > 0 && startWeight > 0) {
          // Tính toán dựa trên quãng đường đã đi được so với mục tiêu
          double totalGap = (targetWeight - startWeight).abs();
          double currentGap = (currentWeight - startWeight).abs();
          progress = (currentGap / totalGap).clamp(0.0, 1.0);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Weight Goal', style: AppTheme.semiboldStyle.copyWith(fontSize: 18)),
                  const Icon(Icons.insights_rounded, color: Colors.grey, size: 22),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                // Gradient giúp card trông sang trọng hơn
                gradient: const LinearGradient(
                  colors: [Color(0xFFF07025), Color(0xFFEA4D2C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF07025).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TARGET WEIGHT',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 11,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: targetWeight > 0 ? targetWeight.toStringAsFixed(1) : '--',
                                  style: AppTheme.headlineStyle.copyWith(fontSize: 42, color: Colors.white),
                                ),
                                TextSpan(
                                  text: ' kg',
                                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // Nút Edit gọn gàng hơn
                      Material(
                        color: Colors.white.withOpacity(0.15),
                        shape: const CircleBorder(),
                        child: IconButton(
                          icon: const Icon(Icons.edit_note_rounded, color: Colors.white),
                          onPressed: () {}, // Mở bottom sheet edit
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Progress Bar tinh tế hơn
                  Column(
                    children: [
                      Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          Container(
                            height: 8,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          // Thanh tiến trình thực tế
                          LayoutBuilder(
                            builder: (context, constraints) {
                              return Container(
                                height: 8,
                                width: constraints.maxWidth * progress,
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildWeightLabel("Current", "$currentWeight kg"),
                          _buildWeightLabel("Left", "${(targetWeight - currentWeight).abs().toStringAsFixed(1)} kg"),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWeightLabel(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11)),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
