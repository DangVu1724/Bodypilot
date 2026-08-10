import 'package:flutter/material.dart' hide StepState;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/data/repositories/step_repository.dart';
import 'package:mobile/presentation/bloc/step/step_cubit.dart';
import 'package:mobile/presentation/bloc/step/step_state.dart';

class StepDetailScreen extends StatelessWidget {
  const StepDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;

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
          top: false,
          child: Column(
            children: [
              // Custom Header
              Container(
                padding: EdgeInsets.fromLTRB(16, statusBarHeight + 10, 16, 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Nhật Ký Bước Chân',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                      tooltip: 'Tải lại lịch sử',
                      onPressed: () {
                        context.read<StepCubit>().fetchStepHistory();
                      },
                    ),
                  ],
                ),
              ),

              // Content Body
              Expanded(
                child: BlocBuilder<StepCubit, StepState>(
                  builder: (context, state) {
                    return RefreshIndicator(
                      onRefresh: () async {
                        await context.read<StepCubit>().fetchStepHistory();
                      },
                      child: CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          // Today summary card
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              child: _buildTodayCard(state),
                            ),
                          ),

                          // Last 7 days quick bar chart
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              child: _buildWeeklyChartSection(state),
                            ),
                          ),

                          // History section title
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                              child: Text(
                                'Lịch Sử Các Ngày Trước',
                                style: GoogleFonts.beVietnamPro(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                            ),
                          ),

                          // History List
                          if (state.isLoadingHistory)
                            const SliverFillRemaining(
                              hasScrollBody: false,
                              child: Center(
                                child: CircularProgressIndicator(color: AppTheme.primary),
                              ),
                            )
                          else if (state.history.isEmpty)
                            SliverToBoxAdapter(
                              child: Container(
                                margin: const EdgeInsets.all(20),
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  children: [
                                    const Icon(Icons.directions_walk_rounded, size: 48, color: Colors.grey),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Chưa có lịch sử bước chân',
                                      style: GoogleFonts.beVietnamPro(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF334155)),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Dữ liệu số bước hàng ngày của bạn sẽ tự động được lưu trữ tại đây.',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final item = state.history[index];
                                    return _buildHistoryItemCard(item, state.targetSteps);
                                  },
                                  childCount: state.history.length,
                                ),
                              ),
                            ),

                          const SliverToBoxAdapter(
                            child: SizedBox(height: 30),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodayCard(StepState state) {
    final stepStr = NumberFormat('#,###').format(state.steps);
    final targetStr = NumberFormat('#,###').format(state.targetSteps);
    final calStr = state.caloriesBurned.toStringAsFixed(0);
    final distStr = state.distanceKm.toStringAsFixed(2);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEC4899), Color(0xFFD946EF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD946EF).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Hôm nay (${DateFormat('dd/MM/yyyy').format(DateTime.now())})',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.9)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.flag_rounded, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Mục tiêu: $targetStr',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Circle Progress
              SizedBox(
                width: 90,
                height: 90,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 90,
                      height: 90,
                      child: CircularProgressIndicator(
                        value: state.progress,
                        strokeWidth: 8,
                        backgroundColor: Colors.white.withOpacity(0.25),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const Icon(Icons.directions_walk_rounded, color: Colors.white, size: 36),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // Big Stats
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stepStr,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      'bước chân',
                      style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withOpacity(0.9)),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildMiniStat(Icons.local_fire_department_rounded, '$calStr kcal'),
                        const SizedBox(width: 16),
                        _buildMiniStat(Icons.straighten_rounded, '$distStr km'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.9), size: 16),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildWeeklyChartSection(StepState state) {
    // Generate last 7 days
    final now = DateTime.now();
    final days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));

    final historyMap = <String, int>{};
    for (final h in state.history) {
      final dateKey = DateFormat('yyyy-MM-dd').format(h.date);
      historyMap[dateKey] = h.stepCount;
    }
    // Add today's live step count
    historyMap[DateFormat('yyyy-MM-dd').format(now)] = state.steps;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '7 Ngày Gần Nhất',
            style: GoogleFonts.beVietnamPro(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: days.map((day) {
              final dateKey = DateFormat('yyyy-MM-dd').format(day);
              final stepCount = historyMap[dateKey] ?? 0;
              final heightRatio = (stepCount / state.targetSteps).clamp(0.05, 1.0);
              final isToday = DateFormat('yyyy-MM-dd').format(day) == DateFormat('yyyy-MM-dd').format(now);

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    stepCount > 0 ? (stepCount >= 1000 ? '${(stepCount / 1000).toStringAsFixed(1)}k' : '$stepCount') : '0',
                    style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: isToday ? const Color(0xFFEC4899) : Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 18,
                    height: 80 * heightRatio,
                    decoration: BoxDecoration(
                      color: isToday ? const Color(0xFFEC4899) : (stepCount >= state.targetSteps ? Colors.green[400] : const Color(0xFFA0AEC0)),
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _getShortDayName(day),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                      color: isToday ? const Color(0xFFEC4899) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _getShortDayName(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday: return 'T2';
      case DateTime.tuesday: return 'T3';
      case DateTime.wednesday: return 'T4';
      case DateTime.thursday: return 'T5';
      case DateTime.friday: return 'T6';
      case DateTime.saturday: return 'T7';
      case DateTime.sunday: return 'CN';
      default: return '';
    }
  }

  String _getFormattedDate(DateTime date) {
    final dayName = switch (date.weekday) {
      DateTime.monday => 'Thứ 2',
      DateTime.tuesday => 'Thứ 3',
      DateTime.wednesday => 'Thứ 4',
      DateTime.thursday => 'Thứ 5',
      DateTime.friday => 'Thứ 6',
      DateTime.saturday => 'Thứ 7',
      DateTime.sunday => 'Chủ Nhật',
      _ => '',
    };
    return '$dayName, ${DateFormat('dd/MM/yyyy').format(date)}';
  }

  Widget _buildHistoryItemCard(StepHistoryModel item, int targetSteps) {
    final dateStr = _getFormattedDate(item.date);
    final stepStr = NumberFormat('#,###').format(item.stepCount);
    final isReached = item.stepCount >= targetSteps;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isReached ? Colors.green[50] : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isReached ? Icons.workspace_premium_rounded : Icons.directions_walk_rounded,
              color: isReached ? Colors.green[600] : const Color(0xFF64748B),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateStr,
                  style: GoogleFonts.beVietnamPro(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '🔥 ${item.caloriesBurned.toStringAsFixed(0)} kcal',
                      style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '📏 ${item.distanceKm.toStringAsFixed(2)} km',
                      style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                stepStr,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isReached ? Colors.green[600] : const Color(0xFF334155),
                ),
              ),
              Text(
                'bước',
                style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[500]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
