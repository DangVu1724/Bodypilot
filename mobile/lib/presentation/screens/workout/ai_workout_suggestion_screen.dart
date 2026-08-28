import 'dart:async';

import 'package:core_shared/core_shared.dart';
import 'package:core_shared/models/daily_workout_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/data/repositories/workout_diary_repository.dart';
import 'package:mobile/data/services/token_service.dart';
import 'package:mobile/presentation/bloc/workout/ai_workout_cubit.dart';
import 'package:mobile/presentation/bloc/workout/ai_workout_state.dart';
import 'package:mobile/presentation/screens/workout/widgets/ai_suggestion/workout_ai_focus_sheet.dart';
import 'package:mobile/presentation/screens/workout/widgets/ai_suggestion/workout_ai_loading_widget.dart';
import 'package:mobile/presentation/screens/workout/widgets/ai_suggestion/workout_day_card.dart';

/// Màn hình gợi ý lịch tập AI cá nhân hóa
class AiWorkoutSuggestionScreen extends StatefulWidget {
  final int days;
  final bool startTomorrow;
  const AiWorkoutSuggestionScreen({super.key, this.days = 7, this.startTomorrow = false});

  @override
  State<AiWorkoutSuggestionScreen> createState() => _AiWorkoutSuggestionScreenState();
}

class _AiWorkoutSuggestionScreenState extends State<AiWorkoutSuggestionScreen> {
  late final AiWorkoutCubit _aiWorkoutCubit;
  List<DailyWorkoutModel> _suggestions = [];
  int _selectedDayIndex = 0;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isSaving = false;

  Timer? _loadingTimer;
  int _loadingStepIndex = 0;

  final List<Map<String, String>> _workoutSteps = const [
    {
      'title': 'Phân tích chỉ số cơ thể',
      'desc': 'Đang phân tích thông tin cân nặng, chiều cao & mục tiêu tập luyện...',
    },
    {'title': 'Kiểm tra tiền sử chấn thương', 'desc': 'Rà soát danh sách chấn thương & hạn chế vận động của bạn...'},
    {'title': 'Lọc danh sách bài tập', 'desc': 'Đang truy vấn danh sách bài tập phù hợp nhất từ cơ sở dữ liệu...'},
    {'title': 'AI thiết lập lịch tập', 'desc': 'Gửi dữ liệu sang AI để tạo lịch trình tối ưu theo yêu cầu...'},
  ];

  void _startLoadingTimer() {
    setState(() {
      _loadingStepIndex = 0;
    });
    _loadingTimer?.cancel();
    _loadingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_loadingStepIndex < _workoutSteps.length - 1) {
        setState(() {
          _loadingStepIndex++;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _stopLoadingTimer() {
    _loadingTimer?.cancel();
    _loadingTimer = null;
  }

  @override
  void dispose() {
    _stopLoadingTimer();
    _aiWorkoutCubit.close();
    super.dispose();
  }

  String _selectedFocusBodyPart = 'NONE';

  String get _focusLabel {
    final match = WorkoutAiFocusSheet.focusOptions.firstWhere(
      (opt) => opt['value'] == _selectedFocusBodyPart,
      orElse: () => {'label': 'Không có (Tự động)', 'value': 'NONE'},
    );
    return match['label']!;
  }

  @override
  void initState() {
    super.initState();
    _aiWorkoutCubit = AiWorkoutCubit();
    _startTomorrow = widget.startTomorrow;
    _selectedFocusBodyPart = TokenService.getFocusBodyPart();
    _startLoadingTimer();
    _fetchAiSuggestion();
  }

  void _showFocusSurveyBottomSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return WorkoutAiFocusSheet(
          initialFocus: _selectedFocusBodyPart,
          onSelectFocus: (newFocus) {
            TokenService.saveFocusBodyPart(newFocus);
            setState(() {
              _selectedFocusBodyPart = newFocus;
              _isLoading = true;
            });
            _startLoadingTimer();
            _fetchAiSuggestion();
          },
        );
      },
    );
  }

  bool _startTomorrow = false;

  void _fetchAiSuggestion() {
    _aiWorkoutCubit.fetchAiWorkoutSuggestion(
      days: widget.days,
      startTomorrow: _startTomorrow,
      focusBodyPart: _selectedFocusBodyPart != 'NONE' ? _selectedFocusBodyPart : null,
    );
  }

  Future<void> _applyWorkoutPlan() async {
    if (_suggestions.isEmpty) return;

    try {
      final existingWorkouts = await workoutDiaryRepository.getDailyWorkoutRange(
        _suggestions.first.date,
        _suggestions.last.date,
      );

      if (existingWorkouts.isNotEmpty && mounted) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.warning_rounded, color: Color(0xFFDC2626), size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Đã có lịch tập', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            content: Text(
              'Từ ngày ${DateFormat('dd/MM').format(_suggestions.first.date)} đến ${DateFormat('dd/MM').format(_suggestions.last.date)} bạn đã có lịch tập. Bạn có muốn ghi đè bằng lịch tập mới này không?',
              style: const TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text(
                  'Hủy',
                  style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text(
                  'Đồng ý ghi đè',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );

        if (confirmed != true) return;
      }
    } catch (_) {}

    setState(() {
      _isSaving = true;
    });
    try {
      final List<Map<String, dynamic>> jsonData = _suggestions.map((e) => e.toJson()).toList();
      await workoutDiaryRepository.addMultipleDailyWorkouts(jsonData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Đã lưu lịch tập AI vào nhật ký thành công!'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi lưu lịch tập: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _aiWorkoutCubit,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: BlocConsumer<AiWorkoutCubit, AiWorkoutState>(
          listener: (context, state) {
            if (state is AiWorkoutSuccess) {
              _stopLoadingTimer();
              setState(() {
                _suggestions = state.suggestions;
                _isLoading = false;
                _errorMessage = null;
                _selectedDayIndex = 0;
              });
            } else if (state is AiWorkoutError) {
              _stopLoadingTimer();
              setState(() {
                _isLoading = false;
                _errorMessage = state.message;
              });
            }
          },
          builder: (context, state) {
            final isScreenLoading =
                (state is AiWorkoutLoading || _isLoading) && state is! AiWorkoutSuccess && state is! AiWorkoutError;
            final suggestions = (state is AiWorkoutSuccess) ? state.suggestions : _suggestions;
            final errorMessage = (state is AiWorkoutError) ? state.message : _errorMessage;
            final hasValidSuggestions = !isScreenLoading && errorMessage == null && suggestions.isNotEmpty;

            if (isScreenLoading) {
              return WorkoutAiLoadingWidget(currentStepIndex: _loadingStepIndex, steps: _workoutSteps);
            }

            if (errorMessage != null && suggestions.isEmpty) {
              return _buildErrorStateWidget(errorMessage);
            }

            return Column(
              children: [
                _buildDarkHeader(),
                Expanded(
                  child: hasValidSuggestions
                      ? _buildWorkoutContentWidget(suggestions[_selectedDayIndex])
                      : const SizedBox.shrink(),
                ),
                if (hasValidSuggestions) _buildBottomBarWidget(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorStateWidget(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: const Icon(Icons.cloud_off_rounded, size: 56, color: Colors.red),
            ),
            const SizedBox(height: 24),
            Text(
              'Không Thể Tạo Lịch Tập',
              style: GoogleFonts.workSans(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Đã xảy ra sự cố trong quá trình tạo gợi ý lịch tập từ AI. Vui lòng thử lại sau.',
              style: AppTheme.bodyStyle.copyWith(color: const Color(0xFF64748B), fontSize: 14, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _startLoadingTimer();
                _fetchAiSuggestion();
              },
              child: Text(
                'Thử lại ngay',
                style: GoogleFonts.workSans(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutContentWidget(DailyWorkoutModel dayModel) {
    final items = dayModel.workoutItems;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Danh sách bài tập (${items.length} bài)',
                style: GoogleFonts.workSans(fontSize: 17, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
              ),
              Text(
                'Tổng: ${dayModel.totalCaloriesBurned.toStringAsFixed(0)} kcal',
                style: GoogleFonts.workSans(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFFFF7A30)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: const Center(
                child: Text('Ngày này không có bài tập nào', style: TextStyle(color: Color(0xFF64748B))),
              ),
            )
          else
            ...items.map((item) => WorkoutDayCard(item: item)),
        ],
      ),
    );
  }

  Widget _buildDarkHeader() {
    final weekdays = const ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF131517),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 16, bottom: 24),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                  ),
                ),
                Text(
                  'Gợi ý Lịch Tập',
                  style: GoogleFonts.workSans(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                GestureDetector(
                  onTap: _showFocusSurveyBottomSheet,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF7A30).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFF7A30).withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.tune, color: Color(0xFFFF7A30), size: 16),
                        const SizedBox(width: 4),
                        Text(
                          _focusLabel,
                          style: GoogleFonts.workSans(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 85,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final day = _suggestions[index];
                final isSelected = _selectedDayIndex == index;
                final dayName = weekdays[day.date.weekday - 1];
                final dayNum = day.date.day.toString();

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDayIndex = index;
                    });
                  },
                  child: Container(
                    width: 60,
                    margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFFF7A30) : Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          dayName,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white.withOpacity(0.4),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dayNum,
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBarWidget() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _isSaving ? null : _applyWorkoutPlan,
              child: _isSaving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      'Áp Dụng Lịch Tập Này',
                      style: GoogleFonts.workSans(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
