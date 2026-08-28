import 'dart:async';

import 'package:core_shared/models/daily_eating_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/data/repositories/nutrition_diary_repository.dart';
import 'package:mobile/presentation/bloc/meal/ai_meal_cubit.dart';
import 'package:mobile/presentation/bloc/meal/ai_meal_state.dart';
import 'package:mobile/presentation/screens/meal/widgets/ai_suggestion/ai_meal_suggestion/ai_meal_bottom_bar.dart';
import 'package:mobile/presentation/screens/meal/widgets/ai_suggestion/ai_meal_suggestion/ai_meal_error_view.dart';
import 'package:mobile/presentation/screens/meal/widgets/ai_suggestion/ai_meal_suggestion/ai_meal_header.dart';
import 'package:mobile/presentation/screens/meal/widgets/ai_suggestion/ai_meal_suggestion/ai_meal_loading_view.dart';
import 'package:mobile/presentation/screens/meal/widgets/ai_suggestion/ai_meal_suggestion/ai_meal_slot_card.dart';

class AiMealSuggestionScreen extends StatefulWidget {
  final int days;
  final bool startTomorrow;
  const AiMealSuggestionScreen({super.key, this.days = 7, this.startTomorrow = false});

  @override
  State<AiMealSuggestionScreen> createState() => _AiMealSuggestionScreenState();
}

class _AiMealSuggestionScreenState extends State<AiMealSuggestionScreen> {
  late final AiMealCubit _aiMealCubit;
  List<DailyEatingModel> _suggestions = [];
  int _selectedDayIndex = 0;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isSaving = false;
  bool _isRegenerating = false;
  String? _lastUserFeedback;

  final TextEditingController _feedbackController = TextEditingController();

  Timer? _loadingTimer;
  int _loadingStepIndex = 0;

  final List<Map<String, String>> _mealSteps = const [
    {
      'title': 'Phân tích chỉ số & mục tiêu calo',
      'desc': 'Đang tổng hợp thông tin cân nặng, chiều cao & mục tiêu dinh dưỡng...',
    },
    {
      'title': 'Kiểm tra dị ứng & kiêng kỵ',
      'desc': 'Rà soát danh sách thực phẩm gây dị ứng & nhóm thực phẩm hạn chế...',
    },
    {
      'title': 'Lọc danh sách thực phẩm',
      'desc': 'Đang lựa chọn các loại thực phẩm dinh dưỡng phù hợp nhất từ cơ sở dữ liệu...',
    },
    {'title': 'AI lên thực đơn chi tiết', 'desc': 'Gửi dữ liệu sang AI để tính toán khẩu phần ăn tối ưu...'},
  ];

  late bool _startTomorrow;

  @override
  void initState() {
    super.initState();
    _aiMealCubit = AiMealCubit();
    _startTomorrow = widget.startTomorrow;
    _startLoadingTimer();
    _fetchAiSuggestion();
  }

  void _startLoadingTimer() {
    setState(() {
      _loadingStepIndex = 0;
    });
    _loadingTimer?.cancel();
    _loadingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_loadingStepIndex < _mealSteps.length - 1) {
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
    _feedbackController.dispose();
    _aiMealCubit.close();
    super.dispose();
  }

  void _fetchAiSuggestion() {
    _aiMealCubit.fetchAiMealSuggestion(days: widget.days, startTomorrow: _startTomorrow);
  }

  void _showAiBusyFallbackDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(12)),
                child: const Text('🤖', style: TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'AI Hiện Đang Bận',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Kết nối với AI tạm thời bị gián đoạn hoặc bận.',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
              ),
              SizedBox(height: 8),
              Text(
                'Hệ thống đã tự động thiết lập cho bạn Thực đơn Chuẩn Dinh Dưỡng cá nhân hóa phù hợp với mục tiêu calo & thể trạng của bạn.',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
              ),
            ],
          ),
          actions: [
            OutlinedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _fetchAiSuggestion();
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFF07025)),
                foregroundColor: const Color(0xFFF07025),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Thử lại với AI', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E293B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Dùng Thực Đơn Này', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    });
  }

  void _sendFeedback() {
    final feedbackText = _feedbackController.text.trim();
    if (feedbackText.isEmpty || _isRegenerating || _isLoading || _isSaving) return;

    FocusScope.of(context).unfocus();
    _lastUserFeedback = feedbackText;

    _aiMealCubit.regenerateWithFeedback(days: widget.days, startTomorrow: _startTomorrow, userFeedback: feedbackText);
  }

  Future<void> _applyMealPlan() async {
    if (_suggestions.isEmpty) return;

    try {
      final startDate = _suggestions.first.date;
      final endDate = _suggestions.last.date;

      final rangeList = await nutritionDiaryRepository.getDailyEatingRange(startDate, endDate);
      final daysWithFood = rangeList.where((day) {
        return day.mealSlots.any((slot) => slot.items.isNotEmpty);
      }).toList();

      if (daysWithFood.isNotEmpty && mounted) {
        final dateStr = "${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}";
        final bool? confirmed = await showDialog<bool>(
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
                  child: Text(
                    'Xác Nhận Ghi Đè',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                ),
              ],
            ),
            content: Text(
              'Hệ thống phát hiện bạn đang có thực đơn trong ${daysWithFood.length} ngày (khoảng $dateStr).\n\nViệc áp dụng thực đơn AI mới sẽ XÓA TOÀN BỘ thực đơn cũ trong các ngày này và GHI ĐÈ bằng thực đơn mới.\n\nBạn có chắc chắn muốn ghi đè không?',
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
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Đồng ý ghi đè', style: TextStyle(fontWeight: FontWeight.bold)),
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
      await nutritionDiaryRepository.addMultipleDailyEatings(jsonData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã áp dụng thực đơn gợi ý của AI vào lịch ăn uống thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi khi áp dụng thực đơn: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _aiMealCubit,
      child: BlocConsumer<AiMealCubit, AiMealState>(
        listener: (context, state) {
          if (state is AiMealLoading) {
            _startLoadingTimer();
            if (mounted) {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });
            }
          } else if (state is AiMealRegenerating) {
            _startLoadingTimer();
            if (mounted) {
              setState(() {
                _isRegenerating = true;
              });
            }
          } else if (state is AiMealSuccess) {
            _stopLoadingTimer();
            if (mounted) {
              setState(() {
                _isLoading = false;
                _isRegenerating = false;
                _suggestions = state.suggestions;
                if (state.isRegenerated) {
                  _feedbackController.clear();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('AI đã cập nhật thực đơn theo phản hồi của bạn!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              });
              if (state.isFallback) {
                _showAiBusyFallbackDialog();
              }
            }
          } else if (state is AiMealError) {
            _stopLoadingTimer();
            if (mounted) {
              setState(() {
                _isLoading = false;
                _isRegenerating = false;
                _errorMessage = state.message;
              });
            }
          }
        },
        builder: (context, state) {
          final isScreenLoading =
              (state is AiMealLoading || state is AiMealRegenerating || _isLoading || _isRegenerating) &&
              state is! AiMealSuccess &&
              state is! AiMealError;
          final suggestions = (state is AiMealSuccess) ? state.suggestions : _suggestions;
          final errorMessage = (state is AiMealError) ? state.message : _errorMessage;
          final hasValidSuggestions = !isScreenLoading && errorMessage == null && suggestions.isNotEmpty;

          return Scaffold(
            backgroundColor: Colors.white,
            body: isScreenLoading
                ? AiMealLoadingView(loadingStepIndex: _loadingStepIndex, mealSteps: _mealSteps)
                : (errorMessage != null || suggestions.isEmpty)
                ? AiMealErrorView(onRetry: _fetchAiSuggestion, onBack: () => Navigator.of(context).pop())
                : _buildContentState(),
            bottomNavigationBar: hasValidSuggestions
                ? AiMealBottomBar(
                    feedbackController: _feedbackController,
                    isRegenerating: _isRegenerating,
                    isSaving: _isSaving,
                    isLoading: _isLoading,
                    onSendFeedback: _sendFeedback,
                    onCancel: () => Navigator.of(context).pop(),
                    onApply: _applyMealPlan,
                  )
                : null,
          );
        },
      ),
    );
  }

  Widget _buildContentState() {
    if (_suggestions.isEmpty) {
      return AiMealErrorView(onRetry: _fetchAiSuggestion, onBack: () => Navigator.of(context).pop());
    }
    final safeIndex = _selectedDayIndex.clamp(0, _suggestions.length - 1);
    final currentDay = _suggestions[safeIndex];
    final dateString = DateFormat('dd/MM/yyyy').format(currentDay.date);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with Date Selector
        AiMealHeader(
          suggestions: _suggestions,
          selectedDayIndex: _selectedDayIndex,
          onSelectDay: (index) => setState(() => _selectedDayIndex = index),
          onBack: () => Navigator.of(context).pop(),
        ),

        // Content Scroll
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!currentDay.isAiGenerated) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.smart_toy_outlined, color: Color(0xFF475569), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Thực đơn chuẩn do Hệ thống tự động thiết lập (kết nối AI gián đoạn).',
                            style: GoogleFonts.workSans(
                              fontSize: 12.5,
                              color: const Color(0xFF334155),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _fetchAiSuggestion,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Thử lại AI',
                            style: TextStyle(color: Color(0xFFF07025), fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFCD34D)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Khuyến cáo: Đề xuất từ AI/Hệ thống chỉ mang tính chất tham khảo cá nhân, không đảm bảo chính xác tuyệt đối và không thay thế chẩn đoán y khoa.',
                          style: GoogleFonts.workSans(
                            fontSize: 12,
                            color: const Color(0xFF92400E),
                            fontWeight: FontWeight.w500,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_lastUserFeedback != null && _lastUserFeedback!.isNotEmpty) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFFEDD5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.chat_bubble_outline, color: Color(0xFFFF7A30), size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Phản hồi của bạn: "$_lastUserFeedback"',
                            style: GoogleFonts.workSans(
                              fontSize: 13,
                              color: const Color(0xFFC2410C),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Day summary info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Thực đơn Ngày $dateString',
                      style: GoogleFonts.workSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF131517),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF7A30).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${currentDay.totalCaloriesPlanned.toStringAsFixed(0)} kcal',
                        style: GoogleFonts.workSans(
                          color: const Color(0xFFFF7A30),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Note / Daily overview card
                if (currentDay.note != null && currentDay.note!.isNotEmpty) _buildDailyOverviewCard(currentDay.note!),

                const SizedBox(height: 20),

                // List of meal slots
                ...currentDay.mealSlots.map((slot) => AiMealSlotCard(slot: slot)),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDailyOverviewCard(String note) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFFF7A30), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              note,
              style: AppTheme.bodyStyle.copyWith(color: const Color(0xFF334155), fontSize: 13.5, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}
