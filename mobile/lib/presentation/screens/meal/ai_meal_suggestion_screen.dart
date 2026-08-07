import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/data/services/token_service.dart';
import 'package:mobile/data/repositories/user_repository.dart';
import 'package:mobile/data/repositories/nutrition_diary_repository.dart';
import 'package:core_shared/models/daily_eating_model.dart';
import 'package:mobile/core/utils/category_image_helper.dart';

class AiMealSuggestionScreen extends StatefulWidget {
  final int days;
  final bool startTomorrow;
  const AiMealSuggestionScreen({super.key, this.days = 7, this.startTomorrow = false});

  @override
  State<AiMealSuggestionScreen> createState() => _AiMealSuggestionScreenState();
}

class _AiMealSuggestionScreenState extends State<AiMealSuggestionScreen> {
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

  final List<Map<String, String>> _mealSteps = [
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
    {
      'title': 'AI lên thực đơn chi tiết',
      'desc': 'Gửi dữ liệu sang AI để tính toán khẩu phần ăn tối ưu...',
    },
  ];

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
    super.dispose();
  }

  final Map<MealType, String> _mealTypeNames = {
    MealType.BREAKFAST: 'Bữa sáng',
    MealType.LUNCH: 'Bữa trưa',
    MealType.DINNER: 'Bữa tối',
    MealType.SNACK: 'Bữa phụ / Bữa xế',
  };

  final Map<MealType, IconData> _mealTypeIcons = {
    MealType.BREAKFAST: Icons.wb_sunny_outlined,
    MealType.LUNCH: Icons.wb_twilight,
    MealType.DINNER: Icons.nightlight_round_outlined,
    MealType.SNACK: Icons.apple_outlined,
  };

  late bool _startTomorrow;

  @override
  void initState() {
    super.initState();
    _startTomorrow = widget.startTomorrow;
    _fetchAiSuggestion();
  }

  Future<void> _fetchAiSuggestion() async {
    _startLoadingTimer();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final userId = TokenService.getUserId();
      if (userId == null) {
        throw Exception("Không tìm thấy thông tin tài khoản người dùng.");
      }
      final startDateStr = DateFormat('yyyy-MM-dd').format(
        _startTomorrow ? DateTime.now().add(const Duration(days: 1)) : DateTime.now(),
      );
      final jsonString = await userRepository.getAiDietSuggestion(
        userId,
        days: widget.days,
        startDate: startDateStr,
      );
      final List<dynamic> decoded = jsonDecode(jsonString) as List<dynamic>;
      final suggestions = decoded.map((e) => DailyEatingModel.fromJson(e as Map<String, dynamic>)).toList();
      if (mounted) {
        setState(() {
          _suggestions = suggestions;
        });
      }
    } catch (e, stackTrace) {
      print("🚨 [AiMealSuggestionScreen Error]: $e");
      print("   StackTrace: $stackTrace");
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll("Exception: ", "");
        });
      }
    } finally {
      _stopLoadingTimer();
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _toggleStartDate(bool startTomorrow) {
    if (_isLoading || _isRegenerating || _isSaving) return;
    setState(() {
      _startTomorrow = startTomorrow;
      _selectedDayIndex = 0;
    });
    _fetchAiSuggestion();
  }

  Future<void> _sendFeedback() async {
    final feedbackText = _feedbackController.text.trim();
    if (feedbackText.isEmpty || _isRegenerating || _isLoading || _isSaving) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isRegenerating = true;
      _lastUserFeedback = feedbackText;
    });

    _startLoadingTimer();

    try {
      final userId = TokenService.getUserId();
      if (userId == null) {
        throw Exception("Không tìm thấy thông tin tài khoản người dùng.");
      }
      final startDateStr = DateFormat('yyyy-MM-dd').format(
        _startTomorrow ? DateTime.now().add(const Duration(days: 1)) : DateTime.now(),
      );
      final jsonString = await userRepository.getAiDietSuggestion(
        userId,
        days: widget.days,
        startDate: startDateStr,
        userFeedback: feedbackText,
      );
      final List<dynamic> decoded = jsonDecode(jsonString) as List<dynamic>;
      final suggestions = decoded.map((e) => DailyEatingModel.fromJson(e as Map<String, dynamic>)).toList();
      if (mounted) {
        setState(() {
          _suggestions = suggestions;
          _feedbackController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI đã cập nhật thực đơn theo phản hồi của bạn!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print("🚨 [AiMealSuggestionScreen Feedback Error]: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể điều chỉnh thực đơn: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _stopLoadingTimer();
      if (mounted) {
        setState(() {
          _isRegenerating = false;
        });
      }
    }
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
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(10),
                  ),
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
                child: const Text('Hủy', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
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
    } catch (e) {
      print("🚨 [AiMealSuggestionScreen] Error checking existing meals before apply: $e");
    }

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi áp dụng thực đơn: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasValidSuggestions = !_isLoading && !_isRegenerating && _errorMessage == null && _suggestions.isNotEmpty;
    return Scaffold(
      backgroundColor: Colors.white,
      body: (_isLoading || _isRegenerating)
          ? _buildLoadingState()
          : (_errorMessage != null || _suggestions.isEmpty)
              ? _buildErrorState()
              : _buildContentState(),
      bottomNavigationBar: hasValidSuggestions ? _buildBottomBar() : null,
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF07025).withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: const SizedBox(
                width: 64,
                height: 64,
                child: CircularProgressIndicator(
                  strokeWidth: 5,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF07025)),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Đang Thiết Lập Thực Đơn AI',
              style: GoogleFonts.workSans(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Vui lòng chờ trong giây lát. Hệ thống đang rà soát dữ liệu thể trạng và phân bổ năng lượng tối ưu.',
              style: AppTheme.bodyStyle.copyWith(color: const Color(0xFF64748B), fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 36),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: List.generate(_mealSteps.length, (index) {
                  final step = _mealSteps[index];
                  final isDone = index < _loadingStepIndex;
                  final isCurrent = index == _loadingStepIndex;

                  return Padding(
                    padding: EdgeInsets.only(bottom: index == _mealSteps.length - 1 ? 0 : 20.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isDone)
                          const Icon(Icons.check_circle, color: Colors.green, size: 22)
                        else if (isCurrent)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF07025)),
                            ),
                          )
                        else
                          const Icon(Icons.radio_button_unchecked, color: Color(0xFF94A3B8), size: 22),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                step['title']!,
                                style: AppTheme.semiboldStyle.copyWith(
                                  fontSize: 15,
                                  color: isCurrent 
                                      ? const Color(0xFFF07025)
                                      : (isDone ? const Color(0xFF334155) : const Color(0xFF94A3B8)),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                step['desc']!,
                                style: AppTheme.bodyStyle.copyWith(
                                  fontSize: 12.5,
                                  color: isCurrent 
                                      ? const Color(0xFF475569) 
                                      : (isDone ? const Color(0xFF64748B) : const Color(0xFFCBD5E1)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    final rawMsg = _errorMessage ?? '';
    final isGeminiQuotaError = rawMsg.contains('429') ||
        rawMsg.toLowerCase().contains('quota') ||
        rawMsg.toLowerCase().contains('rate limit') ||
        rawMsg.toLowerCase().contains('exhausted') ||
        rawMsg.toLowerCase().contains('token') ||
        rawMsg.toLowerCase().contains('gemini');

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isGeminiQuotaError
                    ? Colors.amber.withValues(alpha: 0.12)
                    : Colors.red.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isGeminiQuotaError
                    ? Icons.hourglass_top_rounded
                    : Icons.cloud_off_rounded,
                size: 56,
                color: isGeminiQuotaError ? Colors.amber[800] : Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isGeminiQuotaError
                  ? 'Lỗi Hạn Ngạch AI (Gemini Quota Exceeded)'
                  : 'Không thể khởi tạo thực đơn AI',
              style: GoogleFonts.workSans(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              isGeminiQuotaError
                  ? 'Dịch vụ AI Gemini hiện tại đã hết lượt dùng miễn phí hoặc vượt quá hạn ngạch cho phép (HTTP 429).'
                  : 'Đã xảy ra sự cố trong quá trình tạo gợi ý thực đơn từ AI.',
              style: AppTheme.bodyStyle.copyWith(
                color: const Color(0xFF64748B),
                fontSize: 14,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Diagnostic & Tips Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isGeminiQuotaError
                    ? Colors.amber.withValues(alpha: 0.08)
                    : Colors.grey.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isGeminiQuotaError
                      ? Colors.amber.withValues(alpha: 0.3)
                      : Colors.grey.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: isGeminiQuotaError
                            ? Colors.amber[800]
                            : AppTheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Hướng dẫn xử lý:',
                        style: AppTheme.semiboldStyle.copyWith(
                          fontSize: 14,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '1. Thử lại sau 1 - 2 phút (Google AI sẽ tự động reset lượt gọi).',
                    style: AppTheme.bodyStyle.copyWith(fontSize: 13, color: const Color(0xFF334155)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '2. Thay thế API Key Gemini mới trong backend local nếu liên tục lỗi.',
                    style: AppTheme.bodyStyle.copyWith(fontSize: 13, color: const Color(0xFF334155)),
                  ),
                  if (rawMsg.isNotEmpty) ...[
                    const Divider(height: 20),
                    Text(
                      'Chi tiết lỗi: $rawMsg',
                      style: AppTheme.bodyStyle.copyWith(
                        fontSize: 12,
                        color: Colors.red[700],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _fetchAiSuggestion,
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text(
                  'Thử lại ngay',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7A30),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Quay lại',
                style: AppTheme.semiboldStyle.copyWith(color: AppTheme.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentState() {
    if (_suggestions.isEmpty) {
      return _buildErrorState();
    }
    final safeIndex = _selectedDayIndex.clamp(0, _suggestions.length - 1);
    final currentDay = _suggestions[safeIndex];
    final dateString = DateFormat('dd/MM/yyyy').format(currentDay.date);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dark Header
        _buildDarkHeader(),

        // Content Scroll
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                          'Khuyến cáo: Đề xuất từ AI chỉ mang tính chất tham khảo cá nhân, không đảm bảo chính xác tuyệt đối và không thay thế chẩn đoán y khoa.',
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
                if (currentDay.note != null && currentDay.note!.isNotEmpty)
                  _buildDailyOverviewCard(currentDay.note!),
                
                const SizedBox(height: 20),

                // List of meal slots
                ...currentDay.mealSlots.map((slot) => _buildMealSlotCard(slot)),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
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
          // Navigation Row
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
                  'Gợi ý Thực đơn AI',
                  style: GoogleFonts.workSans(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 44), // Placeholder for balance
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Horizontal Date selector
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
              style: AppTheme.bodyStyle.copyWith(
                color: const Color(0xFF334155),
                fontSize: 13.5,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealSlotCard(MealSlotModel slot) {
    final mealName = _mealTypeNames[slot.mealType] ?? slot.customName ?? 'Bữa ăn';
    final mealIcon = _mealTypeIcons[slot.mealType] ?? Icons.restaurant_menu;
    final totalCalories = slot.items.fold<double>(0, (sum, item) => sum + item.caloriesSnapshot);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Meal Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF7A30).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(mealIcon, color: const Color(0xFFFF7A30), size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  mealName,
                  style: GoogleFonts.workSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const Spacer(),
                Text(
                  '${totalCalories.toStringAsFixed(0)} kcal',
                  style: GoogleFonts.workSans(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),

          // Meal Items list
          if (slot.items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Không có gợi ý món ăn cho bữa này.',
                style: AppTheme.bodyStyle.copyWith(color: AppTheme.textSecondary),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: slot.items.length,
              separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
              itemBuilder: (context, index) {
                final item = slot.items[index];
                return _buildMealItemRow(item);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMealItemRow(MealItemModel item) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Food Image
          CategoryFoodImage(
            imageUrl: item.imageUrlSnapshot,
            categoryName: item.foodNameSnapshot,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.circular(12),
          ),
          const SizedBox(width: 14),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.foodNameSnapshot,
                  style: GoogleFonts.workSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Định lượng: ${item.servingQuantity.toStringAsFixed(0)} ${item.servingUnitSnapshot ?? 'g'}',
                  style: AppTheme.bodyStyle.copyWith(color: AppTheme.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 8),

                // Macros row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMacroItem('${item.caloriesSnapshot.toStringAsFixed(0)} kcal', Icons.local_fire_department, Colors.orange),
                    _buildMacroItem('P: ${item.proteinSnapshot.toStringAsFixed(0)}g', Icons.fitness_center, Colors.blue),
                    _buildMacroItem('F: ${item.fatSnapshot.toStringAsFixed(0)}g', Icons.opacity, Colors.red),
                    _buildMacroItem('C: ${item.carbsSnapshot.toStringAsFixed(0)}g', Icons.grain, Colors.green),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroItem(String value, IconData icon, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 4),
        Text(
          value,
          style: GoogleFonts.workSans(
            fontSize: 11,
            color: const Color(0xFF475569),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.of(context).padding.bottom + 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Feedback Chat Input Field
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Color(0xFFFF7A30), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _feedbackController,
                    enabled: !_isRegenerating && !_isSaving,
                    style: GoogleFonts.workSans(fontSize: 13.5, color: const Color(0xFF0F172A)),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendFeedback(),
                    decoration: const InputDecoration(
                      hintText: 'Nhập phản hồi với AI (VD: Đổi món sáng...)',
                      hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                _isRegenerating
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF7A30)),
                        ),
                      )
                    : InkWell(
                        onTap: (_isSaving || _isLoading) ? null : _sendFeedback,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF7A30),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.send_rounded, color: Colors.white, size: 15),
                        ),
                      ),
              ],
            ),
          ),

          // Action Buttons (Hủy & Áp dụng thực đơn)
          Row(
            children: [
              Expanded(
                flex: 2,
                child: OutlinedButton(
                  onPressed: (_isSaving || _isRegenerating) ? null : () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF64748B),
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Hủy'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: ElevatedButton(
                  onPressed: (_isSaving || _isRegenerating) ? null : _applyMealPlan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7A30),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Áp dụng thực đơn'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
