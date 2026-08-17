import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme.dart';
import '../../data/models/admin_stats_model.dart';
import '../../data/repositories/admin_repository.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with AutomaticKeepAliveClientMixin {
  late Future<AdminStatsModel> _statsFuture;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _statsFuture = adminRepository.getDashboardStats();
  }

  void _refreshStats() {
    setState(() {
      _statsFuture = adminRepository.getDashboardStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<AdminStatsModel>(
      future: _statsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Lỗi tải dữ liệu: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _refreshStats,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Thử lại'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
                ),
              ],
            ),
          );
        }

        final stats = snapshot.data!;

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
                              // Row 2: Smooth Dual Line Chart & Donut Chart
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(flex: 2, child: _buildDualLineChartCard(stats)),
                                  const SizedBox(width: 20),
                                  Expanded(child: _buildDonutCategoryCard(stats)),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Row 3: Weekly Bar Chart & Category Breakdown
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(flex: 2, child: _buildWeeklyBarChartCard()),
                                  const SizedBox(width: 20),
                                  Expanded(child: _buildCategoryBreakdownCard()),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Row 4: Recent Users Table Card
                              _buildRecentUsersTableCard(stats),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),

                        // Right Sidebar: Featured & Recent Activity Timeline
                        SizedBox(
                          width: 320,
                          child: Column(
                            children: [
                              _buildTrendingItemsCard(),
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
                        _buildDualLineChartCard(stats),
                        const SizedBox(height: 24),
                        _buildDonutCategoryCard(stats),
                        const SizedBox(height: 24),
                        _buildWeeklyBarChartCard(),
                        const SizedBox(height: 24),
                        _buildRecentUsersTableCard(stats),
                        const SizedBox(height: 24),
                        _buildTrendingItemsCard(),
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

  // 1. Top Stat Cards (Exact Reztro template style)
  Widget _buildTopStatCards(AdminStatsModel stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 800;
        return Row(
          children: [
            Expanded(
              child: _ReztroStatCard(
                icon: Icons.people_alt_rounded,
                title: 'Tổng người dùng',
                value: stats.totalUsers.toString(),
                trend: '+${stats.userGrowthPercentage}%',
                isUp: true,
              ),
            ),
            SizedBox(width: isNarrow ? 12 : 20),
            Expanded(
              child: _ReztroStatCard(
                icon: Icons.fitness_center_rounded,
                title: 'Tổng bài tập',
                value: stats.totalExercises.toString(),
                trend: '+2.4%',
                isUp: true,
              ),
            ),
            SizedBox(width: isNarrow ? 12 : 20),
            Expanded(
              child: _ReztroStatCard(
                icon: Icons.restaurant_rounded,
                title: 'Tổng món ăn',
                value: stats.totalDishes.toString(),
                trend: '+1.8%',
                isUp: true,
              ),
            ),
          ],
        );
      },
    );
  }

  // 2. Smooth Dual Line Chart (Reztro Income vs Expense style)
  Widget _buildDualLineChartCard(AdminStatsModel stats) {
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
                    'Thống kê đăng ký mới 7 ngày qua',
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
                    Text('7 ngày qua', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textSecondary)),
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
              _buildLegendDot(color: AppTheme.primaryColor, label: 'Người dùng mới'),
              const SizedBox(width: 20),
              _buildLegendDot(color: const Color(0xFF1E293B), label: 'Lượt tập luyện'),
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
                      getTitlesWidget: (val, meta) => Text(val.toInt().toString(), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (idx >= 0 && idx < stats.userGrowthChart.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(stats.userGrowthChart[idx].date, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
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
                  // Orange Line (Primary)
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
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.primaryColor.withValues(alpha: 0.08),
                    ),
                    spots: stats.userGrowthChart.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), e.value.count.toDouble());
                    }).toList(),
                  ),
                  // Dark Line (Secondary)
                  LineChartBarData(
                    isCurved: true,
                    color: const Color(0xFF334155),
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    spots: stats.userGrowthChart.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), (e.value.count * 0.7).clamp(0, 100).toDouble());
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

  // 3. Donut Category Card (Top Categories in Reztro template)
  Widget _buildDonutCategoryCard(AdminStatsModel stats) {
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
          SizedBox(
            height: 160,
            child: Stack(
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 4,
                    centerSpaceRadius: 45,
                    sections: [
                      PieChartSectionData(color: AppTheme.primaryColor, value: 40, title: '', radius: 22),
                      PieChartSectionData(color: const Color(0xFFFFB09C), value: 25, title: '', radius: 22),
                      PieChartSectionData(color: const Color(0xFF1E293B), value: 20, title: '', radius: 22),
                      PieChartSectionData(color: const Color(0xFF94A3B8), value: 15, title: '', radius: 22),
                    ],
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${stats.totalDishes + stats.totalExercises}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                      ),
                      const Text('Mục dữ liệu', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildLegendDot(color: AppTheme.primaryColor, label: 'Món ăn (40%)'),
              _buildLegendDot(color: const Color(0xFFFFB09C), label: 'Bài tập (25%)'),
              _buildLegendDot(color: const Color(0xFF1E293B), label: 'Nguyên liệu (20%)'),
              _buildLegendDot(color: const Color(0xFF94A3B8), label: 'Khác (15%)'),
            ],
          ),
        ],
      ),
    );
  }

  // 4. Weekly Bar Chart (Orders Overview style in Reztro template)
  Widget _buildWeeklyBarChartCard() {
    final days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final values = [120, 140, 130, 185, 160, 150, 145];

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
              const Text('Tần suất Hoạt động Tuần', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(12)),
                child: const Text('Tuần này', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 200,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (idx >= 0 && idx < days.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(days[idx], style: TextStyle(color: idx == 3 ? AppTheme.primaryColor : AppTheme.textSecondary, fontWeight: idx == 3 ? FontWeight.bold : FontWeight.normal, fontSize: 12)),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: values.asMap().entries.map((e) {
                  final isHighlight = e.key == 3;
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value.toDouble(),
                        color: isHighlight ? AppTheme.primaryColor : const Color(0xFFFFF0EB),
                        width: 22,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 5. Category Breakdown / Order Types Card
  Widget _buildCategoryBreakdownCard() {
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
          const Text('Loại hình Tập luyện', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 20),
          _buildProgressRow('Tập Sức mạnh (Strength)', 0.45, '45%', AppTheme.primaryColor),
          const SizedBox(height: 16),
          _buildProgressRow('Cardio & Giảm mỡ', 0.30, '30%', const Color(0xFFFF9D7E)),
          const SizedBox(height: 16),
          _buildProgressRow('Giãn cơ & Yoga', 0.25, '25%', const Color(0xFF1E293B)),
        ],
      ),
    );
  }

  Widget _buildProgressRow(String title, double value, String label, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  // 6. Recent Users Table Card (Reztro Recent Orders Table)
  Widget _buildRecentUsersTableCard(AdminStatsModel stats) {
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
              const Text('Người dùng mới Đăng ký', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              TextButton(
                onPressed: () {},
                child: const Text('Xem tất cả', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 40,
              dataRowMaxHeight: 52,
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8F9FA)),
              columns: const [
                DataColumn(label: Text('Tài khoản', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text('Thời gian', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text('Loại tài khoản', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text('Trạng thái', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              ],
              rows: stats.recentActivities.map((act) {
                return DataRow(
                  cells: [
                    DataCell(
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: AppTheme.primaryLight,
                            child: Text(act.title.substring(act.title.length > 15 ? 15 : act.title.length - 1), style: const TextStyle(fontSize: 11, color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 10),
                          Text(act.title.replaceAll('Người dùng mới: ', ''), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      ),
                    ),
                    DataCell(Text(act.timeAgo, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12))),
                    DataCell(Text(act.type, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('Hoạt động', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // 7. Right Column: Trending Items Card (Exact Reztro Trending Menus Card)
  Widget _buildTrendingItemsCard() {
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
              const Text('Món ăn Nổi bật', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(8)),
                child: const Row(
                  children: [
                    Text('Tuần này', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                    Icon(Icons.keyboard_arrow_down, size: 14, color: AppTheme.textSecondary),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTrendingDishTile(
            imageUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400',
            title: 'Ức gà nướng Salad',
            category: 'Dinh dưỡng Gym',
            rating: '4.9',
            calories: '350 kcal',
          ),
          const SizedBox(height: 16),
          _buildTrendingDishTile(
            imageUrl: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400',
            title: 'Salad Tôm bơ Địa Trung Hải',
            category: 'Eat Clean',
            rating: '4.8',
            calories: '280 kcal',
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingDishTile({
    required String imageUrl,
    required String title,
    required String category,
    required String rating,
    required String calories,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.network(
            imageUrl,
            height: 120,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              height: 120,
              color: const Color(0xFFF1F5F9),
              child: const Icon(Icons.restaurant, color: AppTheme.textSecondary),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary)),
        const SizedBox(height: 2),
        Text(category, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(Icons.star_rounded, size: 16, color: Color(0xFFFFB800)),
            const SizedBox(width: 4),
            Text(rating, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(width: 12),
            const Icon(Icons.local_fire_department_rounded, size: 16, color: AppTheme.primaryColor),
            const SizedBox(width: 4),
            Text(calories, style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ],
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
          const Text('Hoạt động Hệ thống', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
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
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_circle_outline, size: 16, color: AppTheme.primaryColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(act.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppTheme.textPrimary)),
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
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
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
                Text(title, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, letterSpacing: -0.5),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isUp ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(isUp ? Icons.arrow_upward : Icons.arrow_downward, size: 10, color: isUp ? const Color(0xFF10B981) : Colors.red),
                          const SizedBox(width: 2),
                          Text(trend, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isUp ? const Color(0xFF10B981) : Colors.red)),
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
