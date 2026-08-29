import 'package:core_shared/models/daily_eating_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/data/repositories/nutrition_diary_repository.dart';
import 'package:mobile/presentation/bloc/user/user_cubit.dart';
import 'package:mobile/presentation/bloc/user/user_state.dart';

import 'widgets/custom_metric_charts.dart';
import 'package:mobile/presentation/widgets/error_fallback_card.dart';

class ProteinDetailScreen extends StatefulWidget {
  const ProteinDetailScreen({super.key});

  @override
  State<ProteinDetailScreen> createState() => _ProteinDetailScreenState();
}

class _ProteinDetailScreenState extends State<ProteinDetailScreen> {
  bool _isWeekly = true;
  bool _isLoading = true;
  String? _errorMessage;

  List<DailyEatingModel> _eatings = [];

  final Map<String, Map<String, double>> _goalMacros = const {
    'MAINTAIN': {'p': 0.25, 'f': 0.25, 'c': 0.50},
    'LOSE_0_5KG': {'p': 0.35, 'f': 0.25, 'c': 0.40},
    'LOSE_1KG': {'p': 0.40, 'f': 0.20, 'c': 0.40},
    'GAIN_0_5KG': {'p': 0.25, 'f': 0.20, 'c': 0.55},
    'GAIN_1KG': {'p': 0.20, 'f': 0.25, 'c': 0.55},
    'GAIN_MUSCLE': {'p': 0.40, 'f': 0.20, 'c': 0.40},
    'HEALTHY_LIFESTYLE': {'p': 0.25, 'f': 0.30, 'c': 0.45},
  };

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
      final data = await nutritionDiaryRepository.getDailyEatingRange(startDate, now);
      setState(() {
        _eatings = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Không thể tải dữ liệu: $e';
      });
    }
  }

  double _getProteinForDate(DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    double totalProtein = 0.0;

    for (final e in _eatings) {
      if (DateFormat('yyyy-MM-dd').format(e.date) == dateStr) {
        for (final slot in e.mealSlots) {
          for (final item in slot.items) {
            if (item.isEaten) {
              totalProtein += item.proteinSnapshot;
            }
          }
        }
        break;
      }
    }
    return totalProtein;
  }

  List<MealItemModel> _getProteinItemsForDate(DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final List<MealItemModel> proteinItems = [];

    for (final e in _eatings) {
      if (DateFormat('yyyy-MM-dd').format(e.date) == dateStr) {
        for (final slot in e.mealSlots) {
          for (final item in slot.items) {
            if (item.isEaten && item.proteinSnapshot > 0) {
              proteinItems.add(item);
            }
          }
        }
        break;
      }
    }
    // Sắp xếp món nhiều protein trước
    proteinItems.sort((a, b) => b.proteinSnapshot.compareTo(a.proteinSnapshot));
    return proteinItems;
  }

  @override
  Widget build(BuildContext context) {
    final userState = context.watch<UserCubit>().state;
    double targetCalories = 2000.0;
    String goal = 'MAINTAIN';
    if (userState is UserLoaded) {
      targetCalories = userState.user.metrics?.targetCalories ?? 2000.0;
      goal = userState.user.metrics?.goal ?? 'MAINTAIN';
    }

    final macros = _goalMacros[goal] ?? _goalMacros['MAINTAIN']!;
    final double targetProtein = (targetCalories * macros['p']!) / 4;

    final daysCount = _isWeekly ? 7 : 30;
    final dates = List.generate(daysCount, (index) => DateTime.now().subtract(Duration(days: daysCount - 1 - index)));

    final List<double> proteinValues = [];
    final List<String> chartLabels = [];
    double totalProtein = 0;
    double maxProtein = 0;

    for (final date in dates) {
      final p = _getProteinForDate(date);
      proteinValues.add(p);
      totalProtein += p;
      if (p > maxProtein) maxProtein = p;

      if (_isWeekly) {
        final weekday = date.weekday;
        chartLabels.add(weekday == 7 ? 'CN' : 'T${weekday + 1}');
      } else {
        chartLabels.add(DateFormat('dd').format(date));
      }
    }

    final avgProtein = totalProtein / daysCount;

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
              // Header
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
                      'Lượng Protein nạp vào',
                      style: AppTheme.headlineStyle.copyWith(fontSize: 22, color: const Color(0xFF1E293B)),
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
                        ? ErrorFallbackCard(
                            title: 'Không thể tải dữ liệu protein',
                            message: _errorMessage!,
                            onRetry: _fetchData,
                          )
                    : RefreshIndicator(
                        onRefresh: _fetchData,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Stats Grid
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatCard(
                                      'Trung bình/ngày',
                                      '${avgProtein.toStringAsFixed(1)}g',
                                      const Color(0xFF3B82F6),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildStatCard(
                                      'Mục tiêu ngày',
                                      '${targetProtein.toStringAsFixed(0)}g',
                                      const Color(0xFF10B981),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildWideStatCard(
                                'Nạp nhiều nhất một ngày',
                                '${maxProtein.toStringAsFixed(1)}g',
                                Icons.military_tech_rounded,
                                const Color(0xFF8B5CF6),
                              ),
                              const SizedBox(height: 24),

                              // Chart
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Tiến trình nạp Protein',
                                      style: AppTheme.semiboldStyle.copyWith(
                                        fontSize: 16,
                                        color: const Color(0xFF1E293B),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    SingleBarChart(
                                      values: proteinValues,
                                      labels: chartLabels,
                                      target: targetProtein,
                                      unit: 'g',
                                      barColor: const Color(0xFF3B82F6),
                                      barSecondaryColor: const Color(0xFF8B5CF6),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Detailed list
                              Text(
                                'Chi tiết Protein nạp vào',
                                style: AppTheme.semiboldStyle.copyWith(fontSize: 16, color: const Color(0xFF1E293B)),
                              ),
                              const SizedBox(height: 12),
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: dates.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final reverseIndex = dates.length - 1 - index;
                                  final date = dates[reverseIndex];
                                  final p = _getProteinForDate(date);
                                  final items = _getProteinItemsForDate(date);
                                  final dateStr = DateFormat('dd/MM/yyyy').format(date);
                                  final dayName = date.weekday == 7 ? 'Chủ Nhật' : 'Thứ ${date.weekday + 1}';

                                  return Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.8),
                                      borderRadius: BorderRadius.circular(16),
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
                                                  dayName,
                                                  style: AppTheme.semiboldStyle.copyWith(
                                                    fontSize: 14,
                                                    color: const Color(0xFF1E293B),
                                                  ),
                                                ),
                                                Text(
                                                  dateStr,
                                                  style: AppTheme.bodyStyle.copyWith(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: p >= targetProtein
                                                    ? const Color(0xFFECFDF5)
                                                    : const Color(0xFFEFF6FF),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                '${p.toStringAsFixed(1)} g',
                                                style: AppTheme.semiboldStyle.copyWith(
                                                  fontSize: 14,
                                                  color: p >= targetProtein
                                                      ? const Color(0xFF10B981)
                                                      : const Color(0xFF3B82F6),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (items.isNotEmpty) ...[
                                          const Divider(height: 16),
                                          ...items.map(
                                            (item) => Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 4),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      item.foodNameSnapshot,
                                                      style: AppTheme.bodyStyle.copyWith(
                                                        fontSize: 13,
                                                        color: Colors.grey.shade800,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  Text(
                                                    '${item.proteinSnapshot.toStringAsFixed(1)}g đạm',
                                                    style: AppTheme.bodyStyle.copyWith(
                                                      fontSize: 12,
                                                      color: Colors.grey.shade600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.bodyStyle.copyWith(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(value, style: AppTheme.headlineStyle.copyWith(color: color, fontSize: 24)),
        ],
      ),
    );
  }

  Widget _buildWideStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Text(title, style: AppTheme.semiboldStyle.copyWith(color: Colors.grey.shade700, fontSize: 14)),
            ],
          ),
          Text(value, style: AppTheme.headlineStyle.copyWith(color: color, fontSize: 20)),
        ],
      ),
    );
  }
}
