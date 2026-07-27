import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/data/repositories/workout_diary_repository.dart';
import 'package:core_shared/models/daily_workout_model.dart';
import 'widgets/custom_metric_charts.dart';

class ActiveMinutesDetailScreen extends StatefulWidget {
  const ActiveMinutesDetailScreen({super.key});

  @override
  State<ActiveMinutesDetailScreen> createState() => _ActiveMinutesDetailScreenState();
}

class _ActiveMinutesDetailScreenState extends State<ActiveMinutesDetailScreen> {
  bool _isWeekly = true;
  bool _isLoading = true;
  String? _errorMessage;

  List<DailyWorkoutModel> _workouts = [];
  final double _targetActiveMinutes = 45.0; // Target minutes per day

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
      final data = await workoutDiaryRepository.getDailyWorkoutRange(startDate, now);
      setState(() {
        _workouts = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Không thể tải dữ liệu: $e';
      });
    }
  }

  double _getActiveMinutesForDate(DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    double totalMin = 0.0;

    for (final w in _workouts) {
      if (DateFormat('yyyy-MM-dd').format(w.date) == dateStr) {
        for (final item in w.workoutItems) {
          if (item.isCompleted) {
            // Nếu có thời gian snapshot thì cộng, không thì ước lượng 3 phút/bài tập
            totalMin += item.durationMinutesSnapshot ?? 3;
          }
        }
        break;
      }
    }
    return totalMin;
  }

  List<DailyWorkoutItemModel> _getCompletedExercisesForDate(DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final List<DailyWorkoutItemModel> items = [];

    for (final w in _workouts) {
      if (DateFormat('yyyy-MM-dd').format(w.date) == dateStr) {
        for (final item in w.workoutItems) {
          if (item.isCompleted) {
            items.add(item);
          }
        }
        break;
      }
    }
    return items;
  }

  int _getWorkoutCountForRange() {
    int count = 0;
    for (final w in _workouts) {
      if (w.workoutItems.any((item) => item.isCompleted)) {
        count++;
      }
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final daysCount = _isWeekly ? 7 : 30;
    final dates = List.generate(
      daysCount,
      (index) => DateTime.now().subtract(Duration(days: daysCount - 1 - index)),
    );

    final List<double> minutesValues = [];
    final List<String> chartLabels = [];
    double totalActiveMinutes = 0;
    double maxActiveMinutes = 0;

    for (final date in dates) {
      final m = _getActiveMinutesForDate(date);
      minutesValues.add(m);
      totalActiveMinutes += m;
      if (m > maxActiveMinutes) maxActiveMinutes = m;

      if (_isWeekly) {
        final weekday = date.weekday;
        chartLabels.add(weekday == 7 ? 'CN' : 'T${weekday + 1}');
      } else {
        chartLabels.add(DateFormat('dd').format(date));
      }
    }

    final avgMinutes = totalActiveMinutes / daysCount;
    final completedWorkouts = _getWorkoutCountForRange();

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
                      'Thời gian Vận động',
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
                                  // Stats Grid
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildStatCard(
                                          'Tổng số phút',
                                          '${totalActiveMinutes.toStringAsFixed(0)} phút',
                                          const Color(0xFF10B981),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildStatCard(
                                          'Trung bình/ngày',
                                          '${avgMinutes.toStringAsFixed(1)} phút',
                                          const Color(0xFF3B82F6),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  _buildWideStatCard(
                                    'Số ngày đã tập luyện',
                                    '$completedWorkouts ngày',
                                    Icons.fitness_center_rounded,
                                    const Color(0xFF8B5CF6),
                                  ),
                                  const SizedBox(height: 24),

                                  // Chart
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Thời lượng hoạt động (phút)',
                                          style: AppTheme.semiboldStyle.copyWith(
                                            fontSize: 16,
                                            color: const Color(0xFF1E293B),
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        SingleBarChart(
                                          values: minutesValues,
                                          labels: chartLabels,
                                          target: _targetActiveMinutes,
                                          unit: 'phút',
                                          barColor: const Color(0xFF10B981),
                                          barSecondaryColor: const Color(0xFF059669),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Detailed logs
                                  Text(
                                    'Chi tiết bài tập hoàn thành',
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
                                      final reverseIndex = dates.length - 1 - index;
                                      final date = dates[reverseIndex];
                                      final m = _getActiveMinutesForDate(date);
                                      final exercises = _getCompletedExercisesForDate(date);
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
                                                      style: AppTheme.semiboldStyle.copyWith(fontSize: 14, color: const Color(0xFF1E293B)),
                                                    ),
                                                    Text(
                                                      dateStr,
                                                      style: AppTheme.bodyStyle.copyWith(fontSize: 12, color: Colors.grey.shade600),
                                                    ),
                                                  ],
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: m >= _targetActiveMinutes ? const Color(0xFFECFDF5) : const Color(0xFFEFF6FF),
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: Text(
                                                    '${m.toStringAsFixed(0)} phút',
                                                    style: AppTheme.semiboldStyle.copyWith(
                                                      fontSize: 14,
                                                      color: m >= _targetActiveMinutes ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (exercises.isNotEmpty) ...[
                                              const Divider(height: 16),
                                              ...exercises.map((ex) {
                                                String desc = '';
                                                if (ex.durationMinutesSnapshot != null) {
                                                  desc += '${ex.durationMinutesSnapshot} phút';
                                                }
                                                if (ex.setsSnapshot != null) {
                                                  desc += '${desc.isNotEmpty ? " • " : ""}${ex.setsSnapshot} hiệp';
                                                }
                                                if (ex.repsSnapshot != null) {
                                                  desc += ' x ${ex.repsSnapshot} lần';
                                                }

                                                return Padding(
                                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          ex.exerciseNameSnapshot,
                                                          style: AppTheme.bodyStyle.copyWith(fontSize: 13, color: Colors.grey.shade800),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                      Text(
                                                        desc,
                                                        style: AppTheme.bodyStyle.copyWith(fontSize: 12, color: Colors.grey.shade600),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }),
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

  Widget _buildWideStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: AppTheme.semiboldStyle.copyWith(
                  color: Colors.grey.shade700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: AppTheme.headlineStyle.copyWith(
              color: color,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }
}
