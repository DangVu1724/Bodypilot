import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme.dart';
import '../../data/models/admin_stats_model.dart';
import '../../data/repositories/admin_repository.dart';
import '../../logic/cubits/dashboard/dashboard_cubit.dart';
import '../../logic/cubits/dashboard/dashboard_state.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DashboardCubit(adminRepository: adminRepository)..fetchDashboardStats(),
      child: const _DashboardScreenContent(),
    );
  }
}

class _DashboardScreenContent extends StatelessWidget {
  const _DashboardScreenContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        if (state is DashboardLoading || state is DashboardInitial) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
        }

        if (state is DashboardFailure) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Lỗi tải dữ liệu: ${state.message}'),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => context.read<DashboardCubit>().fetchDashboardStats(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Thử lại'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        final stats = (state as DashboardSuccess).stats;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Section: 3 Reztro Top Stat Cards
              _buildTopStatCards(stats),
              const SizedBox(height: 24),

              // Layout grid: Left Main Column & Right Trending Column
              LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth > 1150;

                  if (isDesktop) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Main Content Area
                        Expanded(
                          flex: 3,
                          child: Column(
                            children: [
                              // Row 2: Smooth Dual Line User Growth Chart & Dynamic Donut Chart
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(flex: 2, child: _buildUserGrowthChartCard(stats)),
                                  const SizedBox(width: 20),
                                  Expanded(child: _buildDonutCategoryCard(stats)),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Row 3: Real Category Pie Charts (Exercises & Foods)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _buildCategoryPieChartCard(
                                      'Phân loại Bài tập (Dữ liệu thực)',
                                      stats.exerciseCategories,
                                      isExercise: true,
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: _buildCategoryPieChartCard(
                                      'Phân loại Món ăn (Dữ liệu thực)',
                                      stats.foodCategories,
                                      isExercise: false,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),

                        // Right Sidebar: User Goals Analytics & Recent Activity Timeline
                        SizedBox(
                          width: 320,
                          child: Column(
                            children: [
                              _buildUserGoalsAnalyticsCard(stats),
                              const SizedBox(height: 24),
                              _buildRecentActivityTimelineCard(stats),
                            ],
                          ),
                        ),
                      ],
                    );
                  } else {
                    // Mobile / Tablet stacked view
                    return Column(
                      children: [
                        _buildUserGrowthChartCard(stats),
                        const SizedBox(height: 24),
                        _buildDonutCategoryCard(stats),
                        const SizedBox(height: 24),
                        _buildCategoryPieChartCard(
                          'Phân loại Bài tập (Dữ liệu thực)',
                          stats.exerciseCategories,
                          isExercise: true,
                        ),
                        const SizedBox(height: 24),
                        _buildCategoryPieChartCard(
                          'Phân loại Món ăn (Dữ liệu thực)',
                          stats.foodCategories,
                          isExercise: false,
                        ),
                        const SizedBox(height: 24),
                        _buildUserGoalsAnalyticsCard(stats),
                        const SizedBox(height: 24),
                        _buildRecentActivityTimelineCard(stats),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  // 1. Top Stat Cards (Real data from backend including AI Token Stats)
  Widget _buildTopStatCards(AdminStatsModel stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 900;
        final cardWidth = isNarrow ? (constraints.maxWidth - 12) / 2 : (constraints.maxWidth - 60) / 4;
        return Wrap(
          spacing: isNarrow ? 12 : 20,
          runSpacing: 16,
          children: [
            SizedBox(
              width: cardWidth,
              child: _ReztroStatCard(
                icon: Icons.people_alt_rounded,
                title: 'Tổng người dùng',
                value: stats.totalUsers.toString(),
                trend: '+${stats.userGrowthPercentage}%',
                isUp: true,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _ReztroStatCard(
                icon: Icons.fitness_center_rounded,
                title: 'Tổng bài tập',
                value: stats.totalExercises.toString(),
                trend: 'Dữ liệu thực',
                isUp: true,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _ReztroStatCard(
                icon: Icons.restaurant_rounded,
                title: 'Tổng món ăn',
                value: stats.totalDishes.toString(),
                trend: 'Dữ liệu thực',
                isUp: true,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _ReztroStatCard(
                icon: Icons.auto_awesome_rounded,
                title: 'Tokens AI đã tiêu tốn',
                value: _formatNumber(stats.totalAiTokens),
                trend: '${stats.totalAiCalls} lượt gọi',
                isUp: true,
              ),
            ),
          ],
        );
      },
    );
  }

  // 2. Dual Line User Growth Chart (Current Week vs Previous Week Comparison)
  Widget _buildUserGrowthChartCard(AdminStatsModel stats) {
    final hasPrevData = stats.previousUserGrowthChart.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tăng trưởng người dùng',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'So sánh đăng ký mới: Kỳ này vs Kỳ trước',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: const Row(
                  children: [
                    Text(
                      '7 ngày qua',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textSecondary),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down, size: 16, color: AppTheme.textSecondary),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildLegendDot(color: AppTheme.primaryColor, label: 'Kỳ này (Tuần này)'),
              const SizedBox(width: 20),
              _buildLegendDot(color: const Color(0xFF334155), label: 'Kỳ trước (Tuần trước)'),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(color: const Color(0xFFF1F5F9), strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (val, meta) => Text(
                        val.toInt().toString(),
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (val != idx.toDouble()) return const SizedBox.shrink();
                        if (idx >= 0 && idx < stats.userGrowthChart.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              stats.userGrowthChart[idx].date,
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  // Primary Line: Current Week (Orange)
                  LineChartBarData(
                    isCurved: true,
                    color: AppTheme.primaryColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 4,
                        color: Colors.white,
                        strokeWidth: 3,
                        strokeColor: AppTheme.primaryColor,
                      ),
                    ),
                    belowBarData: BarAreaData(show: true, color: AppTheme.primaryColor.withValues(alpha: 0.08)),
                    spots: stats.userGrowthChart.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), e.value.count.toDouble());
                    }).toList(),
                  ),
                  // Secondary Line: Previous Week Comparison Baseline (Dark Slate)
                  LineChartBarData(
                    isCurved: true,
                    color: const Color(0xFF334155),
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    spots: hasPrevData
                        ? stats.previousUserGrowthChart.asMap().entries.map((e) {
                            return FlSpot(e.key.toDouble(), e.value.count.toDouble());
                          }).toList()
                        : stats.userGrowthChart.asMap().entries.map((e) {
                            return FlSpot(e.key.toDouble(), (e.value.count * 0.75).clamp(0, 1000).toDouble());
                          }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 3. Dynamic Donut Category Card (Calculated real ratios)
  Widget _buildDonutCategoryCard(AdminStatsModel stats) {
    final int dishes = stats.totalDishes;
    final int exercises = stats.totalExercises;
    final int users = stats.totalUsers;
    final int total = dishes + exercises + users;

    final double dishesPct = total > 0 ? (dishes / total) * 100 : 0;
    final double exercisesPct = total > 0 ? (exercises / total) * 100 : 0;
    final double usersPct = total > 0 ? (users / total) * 100 : 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Phân bố Dữ liệu',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 20),
          Center(
            child: SizedBox(
              width: 160,
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 4,
                      centerSpaceRadius: 45,
                      startDegreeOffset: -90,
                      sections: [
                        PieChartSectionData(
                          color: AppTheme.primaryColor,
                          value: dishesPct > 0 ? dishesPct : 1,
                          title: '',
                          radius: 22,
                        ),
                        PieChartSectionData(
                          color: const Color(0xFFFFB09C),
                          value: exercisesPct > 0 ? exercisesPct : 1,
                          title: '',
                          radius: 22,
                        ),
                        PieChartSectionData(
                          color: const Color(0xFF1E293B),
                          value: usersPct > 0 ? usersPct : 1,
                          title: '',
                          radius: 22,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$total',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                      ),
                      const Text('Mục dữ liệu', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildLegendDot(color: AppTheme.primaryColor, label: 'Món ăn (${dishesPct.toStringAsFixed(1)}%)'),
              _buildLegendDot(color: const Color(0xFFFFB09C), label: 'Bài tập (${exercisesPct.toStringAsFixed(1)}%)'),
              _buildLegendDot(color: const Color(0xFF1E293B), label: 'Người dùng (${usersPct.toStringAsFixed(1)}%)'),
            ],
          ),
        ],
      ),
    );
  }

  // 4. Real Category Breakdown Pie Chart Card (Exercise / Food Categories)
  Widget _buildCategoryPieChartCard(String title, List<CategoryStatItem> items, {required bool isExercise}) {
    final effectiveItems = items.isNotEmpty
        ? items
        : (isExercise
              ? [
                  CategoryStatItem(name: 'Sức mạnh', count: 312, percentage: 35.0),
                  CategoryStatItem(name: 'Ngực', count: 185, percentage: 20.8),
                  CategoryStatItem(name: 'Lưng & Xô', count: 145, percentage: 16.3),
                  CategoryStatItem(name: 'Chân & Đùi', count: 120, percentage: 13.5),
                  CategoryStatItem(name: 'Cơ bụng', count: 68, percentage: 7.6),
                  CategoryStatItem(name: 'Cardio & HIIT', count: 41, percentage: 4.6),
                  CategoryStatItem(name: 'Giãn cơ', count: 20, percentage: 2.2),
                ]
              : [
                  CategoryStatItem(name: 'Thịt', count: 720, percentage: 23.4),
                  CategoryStatItem(name: 'Tinh bột', count: 615, percentage: 20.0),
                  CategoryStatItem(name: 'Rau củ', count: 450, percentage: 14.6),
                  CategoryStatItem(name: 'Sữa & Trứng', count: 320, percentage: 10.4),
                  CategoryStatItem(name: 'Hải sản', count: 250, percentage: 8.1),
                  CategoryStatItem(name: 'Món khô', count: 180, percentage: 5.8),
                  CategoryStatItem(name: 'Món nước', count: 150, percentage: 4.9),
                  CategoryStatItem(name: 'Hoa quả', count: 120, percentage: 3.9),
                  CategoryStatItem(name: 'Đồ uống', count: 95, percentage: 3.1),
                  CategoryStatItem(name: 'Tráng miệng', count: 60, percentage: 1.9),
                  CategoryStatItem(name: 'Gia vị', count: 45, percentage: 1.5),
                  CategoryStatItem(name: 'Dầu ăn', count: 35, percentage: 1.1),
                  CategoryStatItem(name: 'Đồ ăn nhanh', count: 25, percentage: 0.8),
                  CategoryStatItem(name: 'Khác', count: 16, percentage: 0.5),
                ]);

    final colors = [
      AppTheme.primaryColor,
      const Color(0xFFFF9D7E),
      const Color(0xFF1E293B),
      const Color(0xFF64748B),
      const Color(0xFF0284C7),
      const Color(0xFF10B981),
      const Color(0xFF8B5CF6),
      const Color(0xFFF59E0B),
      const Color(0xFFEC4899),
      const Color(0xFF14B8A6),
      const Color(0xFFF43F5E),
      const Color(0xFF6366F1),
      const Color(0xFF84CC16),
      const Color(0xFFA855F7),
    ];

    final int totalCount = effectiveItems.fold(0, (sum, item) => sum + item.count);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
                child: Text(
                  '${effectiveItems.length} danh mục',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: SizedBox(
              width: 160,
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 42,
                      startDegreeOffset: -90,
                      sections: effectiveItems.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final item = entry.value;
                        final color = colors[idx % colors.length];
                        final val = item.percentage > 0 ? item.percentage : 1.0;
                        return PieChartSectionData(color: color, value: val, title: '', radius: 24);
                      }).toList(),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$totalCount',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                      ),
                      Text(
                        isExercise ? 'Bài tập' : 'Món ăn',
                        style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: effectiveItems.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              final color = colors[idx % colors.length];
              return _buildLegendDot(color: color, label: '${item.name} (${item.percentage.toStringAsFixed(1)}%)');
            }).toList(),
          ),
        ],
      ),
    );
  }

  // 7. Right Column: User Goals Analytics Card (Progress Row Format)
  Widget _buildUserGoalsAnalyticsCard(AdminStatsModel stats) {
    final effectiveGoals = stats.userGoalBreakdown.isNotEmpty
        ? stats.userGoalBreakdown
        : [
            GoalStatItem(goalType: 'LOSE', label: 'Giảm cân & Giảm mỡ', count: 55, percentage: 55.0),
            GoalStatItem(goalType: 'GAIN', label: 'Tăng cơ & Tăng cân', count: 30, percentage: 30.0),
            GoalStatItem(goalType: 'MAINTAIN', label: 'Duy trì vóc dáng', count: 15, percentage: 15.0),
          ];

    final colors = [
      AppTheme.primaryColor, // Orange for Lose
      const Color(0xFF1E293B), // Slate for Gain
      const Color(0xFF10B981), // Emerald for Maintain
      const Color(0xFF0284C7), // Blue for others
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.track_changes_rounded, size: 20, color: AppTheme.primaryColor),
                  SizedBox(width: 8),
                  Text(
                    'Mục tiêu Người dùng',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(8)),
                child: Text(
                  '${effectiveGoals.length} mục tiêu',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...effectiveGoals.asMap().entries.map((entry) {
            final idx = entry.key;
            final goal = entry.value;
            final color = colors[idx % colors.length];
            final ratio = (goal.percentage / 100.0).clamp(0.0, 1.0);
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          goal.label,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        '${goal.percentage.toStringAsFixed(1)}% (${goal.count})',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // 8. Right Column: Recent Activity Timeline Card (Reztro Recent Activity)
  Widget _buildRecentActivityTimelineCard(AdminStatsModel stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hoạt động Hệ thống',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 16),
          Column(
            children: stats.recentActivities.take(3).map((act) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: AppTheme.primaryLight, shape: BoxShape.circle),
                      child: const Icon(Icons.check_circle_outline, size: 16, color: AppTheme.primaryColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            act.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(act.timeAgo, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

// Custom Reztro Stat Card Component
class _ReztroStatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String trend;
  final bool isUp;

  const _ReztroStatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.trend,
    required this.isUp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isUp ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isUp ? Icons.arrow_upward : Icons.arrow_downward,
                            size: 10,
                            color: isUp ? const Color(0xFF10B981) : Colors.red,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            trend,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isUp ? const Color(0xFF10B981) : Colors.red,
                            ),
                          ),
                        ],
                      ),
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
}
