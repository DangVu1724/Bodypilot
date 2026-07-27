import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/data/repositories/nutrition_diary_repository.dart';
import 'package:mobile/data/repositories/workout_diary_repository.dart';
import 'package:mobile/presentation/bloc/user/user_cubit.dart';
import 'package:mobile/presentation/bloc/user/user_state.dart';
import 'package:core_shared/models/daily_eating_model.dart';
import 'package:core_shared/models/daily_workout_model.dart';
import 'widgets/custom_metric_charts.dart';

class CalorieBalanceDetailScreen extends StatefulWidget {
  const CalorieBalanceDetailScreen({super.key});

  @override
  State<CalorieBalanceDetailScreen> createState() => _CalorieBalanceDetailScreenState();
}

class _CalorieBalanceDetailScreenState extends State<CalorieBalanceDetailScreen> {
  bool _isWeekly = true; // true: 7 days, false: 30 days
  bool _isLoading = true;
  String? _errorMessage;

  List<DailyEatingModel> _eatings = [];
  List<DailyWorkoutModel> _workouts = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final now = DateTime.now();
    final daysToFetch = _isWeekly ? 7 : 30;
    final startDate = now.subtract(Duration(days: daysToFetch - 1));

    try {
      final results = await Future.wait([
        nutritionDiaryRepository.getDailyEatingRange(startDate, now),
        workoutDiaryRepository.getDailyWorkoutRange(startDate, now),
      ]);

      setState(() {
        _eatings = results[0] as List<DailyEatingModel>;
        _workouts = results[1] as List<DailyWorkoutModel>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Không thể tải dữ liệu: $e';
      });
    }
  }

  Map<String, double> _getDataForDate(DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    
    double intake = 0.0;
    for (final e in _eatings) {
      if (DateFormat('yyyy-MM-dd').format(e.date) == dateStr) {
        intake = e.totalCaloriesEaten;
        break;
      }
    }

    double burned = 0.0;
    for (final w in _workouts) {
      if (DateFormat('yyyy-MM-dd').format(w.date) == dateStr) {
        burned = w.totalCaloriesBurned;
        break;
      }
    }

    return {'intake': intake, 'burned': burned};
  }

  @override
  Widget build(BuildContext context) {
    final userState = context.watch<UserCubit>().state;
    double targetCalories = 2000.0;
    if (userState is UserLoaded) {
      targetCalories = userState.user.metrics?.targetCalories ?? 2000.0;
    }

    final daysCount = _isWeekly ? 7 : 30;
    final dates = List.generate(
      daysCount,
      (index) => DateTime.now().subtract(Duration(days: daysCount - 1 - index)),
    );

    final List<double> intakeValues = [];
    final List<double> burnedValues = [];
    final List<String> chartLabels = [];

    double totalIntake = 0;
    double totalBurned = 0;

    for (final date in dates) {
      final data = _getDataForDate(date);
      intakeValues.add(data['intake']!);
      burnedValues.add(data['burned']!);
      
      totalIntake += data['intake']!;
      totalBurned += data['burned']!;

      if (_isWeekly) {
        // Thứ 2 -> CN hoặc viết tắt
        final weekday = date.weekday;
        chartLabels.add(weekday == 7 ? 'CN' : 'T${weekday + 1}');
      } else {
        // Chỉ hiện ngày (dd) để biểu đồ 30 ngày gọn gàng
        chartLabels.add(DateFormat('dd').format(date));
      }
    }

    final avgIntake = totalIntake / daysCount;
    final avgBurned = totalBurned / daysCount;
    final netBalance = avgIntake - avgBurned;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFA0AEC0), // Slate Grey
              Color(0xFFD6CCC2), // Warm Beige
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E293B)),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Cân bằng Calorie',
                      style: AppTheme.headlineStyle.copyWith(
                        fontSize: 22,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),

              // Timeframe selector
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (!_isWeekly) {
                              setState(() {
                                _isWeekly = true;
                              });
                              _fetchData();
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: _isWeekly ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '7 ngày qua',
                              style: AppTheme.semiboldStyle.copyWith(
                                color: _isWeekly ? const Color(0xFF1E293B) : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (_isWeekly) {
                              setState(() {
                                _isWeekly = false;
                              });
                              _fetchData();
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: !_isWeekly ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '30 ngày qua',
                              style: AppTheme.semiboldStyle.copyWith(
                                color: !_isWeekly ? const Color(0xFF1E293B) : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                    : _errorMessage != null
                        ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
                        : RefreshIndicator(
                            onRefresh: _fetchData,
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Stats Row
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildStatCard(
                                          'Nạp vào (Kcal)',
                                          avgIntake.toStringAsFixed(0),
                                          const Color(0xFFF97316),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildStatCard(
                                          'Tiêu hao (Kcal)',
                                          avgBurned.toStringAsFixed(0),
                                          const Color(0xFFEC4899),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Cân bằng ròng (Net)',
                                          style: AppTheme.semiboldStyle.copyWith(
                                            color: const Color(0xFF64748B),
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          '${netBalance.toStringAsFixed(0)} kcal',
                                          style: AppTheme.headlineStyle.copyWith(
                                            color: netBalance > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                                            fontSize: 20,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Chart Card
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(28),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.02),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Xu hướng Calorie ${_isWeekly ? "Tuần" : "Tháng"}',
                                          style: AppTheme.semiboldStyle.copyWith(
                                            fontSize: 16,
                                            color: const Color(0xFF1E293B),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            _buildLegendItem('Nạp vào', const Color(0xFFF97316)),
                                            const SizedBox(width: 12),
                                            _buildLegendItem('Tiêu hao', const Color(0xFFEC4899)),
                                          ],
                                        ),
                                        const SizedBox(height: 24),
                                        DoubleBarChart(
                                          values1: intakeValues,
                                          values2: burnedValues,
                                          labels: chartLabels,
                                          target: targetCalories,
                                          unit: 'kcal',
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Detailed Logs
                                  Text(
                                    'Chi tiết hàng ngày',
                                    style: AppTheme.semiboldStyle.copyWith(
                                      fontSize: 16,
                                      color: const Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: dates.length,
                                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                                    itemBuilder: (context, index) {
                                      // Hiện thị ngày đảo ngược (từ mới nhất đến cũ nhất)
                                      final reverseIndex = dates.length - 1 - index;
                                      final date = dates[reverseIndex];
                                      final data = _getDataForDate(date);
                                      final net = data['intake']! - data['burned']!;
                                      final dateStr = DateFormat('dd/MM/yyyy').format(date);
                                      final dayName = date.weekday == 7 ? 'Chủ Nhật' : 'Thứ ${date.weekday + 1}';

                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.8),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  dayName,
                                                  style: AppTheme.semiboldStyle.copyWith(fontSize: 14, color: const Color(0xFF1E293B)),
                                                ),
                                                Text(
                                                  dateStr,
                                                  style: AppTheme.bodyStyle.copyWith(fontSize: 12, color: Colors.grey.shade600),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.end,
                                                  children: [
                                                    Text(
                                                      '+${data['intake']!.toStringAsFixed(0)} kcal',
                                                      style: AppTheme.bodyStyle.copyWith(fontSize: 12, color: const Color(0xFFF97316), fontWeight: FontWeight.bold),
                                                    ),
                                                    Text(
                                                      '-${data['burned']!.toStringAsFixed(0)} kcal',
                                                      style: AppTheme.bodyStyle.copyWith(fontSize: 12, color: const Color(0xFFEC4899), fontWeight: FontWeight.bold),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(width: 16),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: net > 0 ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: Text(
                                                    '${net > 0 ? "+" : ""}${net.toStringAsFixed(0)}',
                                                    style: AppTheme.semiboldStyle.copyWith(
                                                      fontSize: 13,
                                                      color: net > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 32),
                                ],
                              ),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.bodyStyle.copyWith(
              color: Colors.grey.shade500,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTheme.headlineStyle.copyWith(
              color: color,
              fontSize: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTheme.bodyStyle.copyWith(
            fontSize: 11,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}
