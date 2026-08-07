import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/data/services/token_service.dart';
import 'package:mobile/data/repositories/user_repository.dart';
import 'package:mobile/data/repositories/workout_diary_repository.dart';
import 'package:core_shared/models/daily_workout_model.dart';

class AiWorkoutSuggestionScreen extends StatefulWidget {
  final int days;
  const AiWorkoutSuggestionScreen({super.key, this.days = 7});

  @override
  State<AiWorkoutSuggestionScreen> createState() => _AiWorkoutSuggestionScreenState();
}

class _AiWorkoutSuggestionScreenState extends State<AiWorkoutSuggestionScreen> {
  List<DailyWorkoutModel> _suggestions = [];
  int _selectedDayIndex = 0;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isSaving = false;

  Timer? _loadingTimer;
  int _loadingStepIndex = 0;

  final List<Map<String, String>> _workoutSteps = [
    {
      'title': 'Phân tích chỉ số cơ thể',
      'desc': 'Đang phân tích thông tin cân nặng, chiều cao & mục tiêu tập luyện...',
    },
    {
      'title': 'Kiểm tra tiền sử chấn thương',
      'desc': 'Rà soát danh sách chấn thương & hạn chế vận động của bạn...',
    },
    {
      'title': 'Lọc danh sách bài tập',
      'desc': 'Đang truy vấn danh sách bài tập phù hợp nhất từ cơ sở dữ liệu...',
    },
    {
      'title': 'AI thiết lập lịch tập',
      'desc': 'Gửi dữ liệu sang AI để tạo lịch trình tối ưu theo yêu cầu...',
    },
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
    super.dispose();
  }

  String _selectedFocusBodyPart = 'NONE';
  final List<Map<String, String>> _focusOptions = [
    {'label': 'Không có', 'value': 'NONE'},
    {'label': 'Ngực', 'value': 'CHEST'},
    {'label': 'Lưng', 'value': 'BACK'},
    {'label': 'Chân', 'value': 'LEGS'},
    {'label': 'Vai', 'value': 'SHOULDERS'},
    {'label': 'Tay', 'value': 'ARMS'},
    {'label': 'Bụng / Core', 'value': 'CORE'},
    {'label': 'Toàn thân', 'value': 'FULL_BODY'},
  ];

  String get _focusLabel {
    final match = _focusOptions.firstWhere(
      (opt) => opt['value'] == _selectedFocusBodyPart,
      orElse: () => {'label': 'Không có', 'value': 'NONE'},
    );
    return match['label']!;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showFocusSurveyBottomSheet();
    });
  }

  void _showFocusSurveyBottomSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        String tempSelected = _selectedFocusBodyPart;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.fitness_center, color: AppTheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Khảo sát nhu cầu tập luyện',
                          style: GoogleFonts.workSans(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bạn muốn tập trung tập luyện vào bộ phận nào nhất?',
                    style: AppTheme.bodyStyle.copyWith(color: const Color(0xFF64748B), fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _focusOptions.map((opt) {
                      final isSelected = tempSelected == opt['value'];
                      return ChoiceChip(
                        label: Text(
                          opt['label']!,
                          style: TextStyle(
                            color: isSelected ? Colors.white : const Color(0xFF334155),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppTheme.primary,
                        backgroundColor: const Color(0xFFF1F5F9),
                        onSelected: (selected) {
                          if (selected) {
                            setModalState(() {
                              tempSelected = opt['value']!;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        setState(() {
                          _selectedFocusBodyPart = tempSelected;
                        });
                        _fetchAiSuggestion();
                      },
                      child: Text(
                        'Tạo lịch tập AI',
                        style: GoogleFonts.workSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  bool _startTomorrow = false;

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
      final jsonString = await userRepository.getAiWorkoutSuggestion(
        userId,
        days: widget.days,
        focusBodyPart: _selectedFocusBodyPart,
        startDate: startDateStr,
      );
      final List<dynamic> decoded = jsonDecode(jsonString) as List<dynamic>;
      final suggestions = decoded.map((e) => DailyWorkoutModel.fromJson(e as Map<String, dynamic>)).toList();
      if (mounted) {
        setState(() {
          _suggestions = suggestions;
        });
      }
    } catch (e, stackTrace) {
      print("🚨 [AiWorkoutSuggestionScreen Error]: $e");
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


  Future<void> _applyWorkoutPlan() async {
    if (_suggestions.isEmpty) return;

    try {
      final startDate = _suggestions.first.date;
      final endDate = _suggestions.last.date;

      final rangeList = await workoutDiaryRepository.getDailyWorkoutRange(startDate, endDate);
      final daysWithWorkout = rangeList.where((day) => day.workoutItems.isNotEmpty).toList();

      if (daysWithWorkout.isNotEmpty && mounted) {
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
              'Hệ thống phát hiện bạn đang có lịch tập trong ${daysWithWorkout.length} ngày (khoảng $dateStr).\n\nViệc áp dụng lịch tập AI mới sẽ XÓA TOÀN BỘ lịch tập cũ trong các ngày này và GHI ĐÈ bằng lịch tập mới.\n\nBạn có chắc chắn muốn ghi đè không?',
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
      print("🚨 [AiWorkoutSuggestionScreen] Error checking existing workouts before apply: $e");
    }

    setState(() {
      _isSaving = true;
    });
    try {
      final List<Map<String, dynamic>> jsonData = _suggestions.map((e) => e.toJson()).toList();
      await workoutDiaryRepository.addMultipleDailyWorkouts(jsonData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã áp dụng lịch tập gợi ý của AI thành công!'), backgroundColor: Colors.green),
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
        ).showSnackBar(SnackBar(content: Text('Lỗi khi áp dụng lịch tập: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasValidSuggestions = !_isLoading && _errorMessage == null && _suggestions.isNotEmpty;
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
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
                color: AppTheme.primary.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: const SizedBox(
                width: 64,
                height: 64,
                child: CircularProgressIndicator(
                  strokeWidth: 5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Đang Thiết Lập Lịch Tập AI',
              style: GoogleFonts.workSans(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Vui lòng chờ trong giây lát. Hệ thống đang rà soát dữ liệu thể trạng và phân bổ lịch trình tối ưu.',
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
                children: List.generate(_workoutSteps.length, (index) {
                  final step = _workoutSteps[index];
                  final isDone = index < _loadingStepIndex;
                  final isCurrent = index == _loadingStepIndex;

                  return Padding(
                    padding: EdgeInsets.only(bottom: index == _workoutSteps.length - 1 ? 0 : 20.0),
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
                              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
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
                                      ? AppTheme.primary 
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
                  : 'Không thể khởi tạo lịch tập AI',
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
                  : 'Đã xảy ra sự cố trong quá trình tạo gợi ý lịch tập từ AI.',
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
                  backgroundColor: AppTheme.primary,
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

  void _toggleStartDate(bool startTomorrow) {
    if (_startTomorrow == startTomorrow) return;
    setState(() {
      _startTomorrow = startTomorrow;
      if (_suggestions.isNotEmpty) {
        final now = DateTime.now();
        final baseDate = startTomorrow
            ? DateTime(now.year, now.month, now.day).add(const Duration(days: 1))
            : DateTime(now.year, now.month, now.day);
        _suggestions = List.generate(_suggestions.length, (i) {
          final model = _suggestions[i];
          final newDate = baseDate.add(Duration(days: i));
          return DailyWorkoutModel(
            id: model.id,
            date: newDate,
            note: model.note,
            isAiGenerated: model.isAiGenerated,
            totalCaloriesPlanned: model.totalCaloriesPlanned,
            totalCaloriesBurned: model.totalCaloriesBurned,
            isCompleted: model.isCompleted,
            workoutItems: model.workoutItems,
          );
        });
      }
    });
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
        _buildDarkHeader(),
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
                          'Khuyến cáo: Lịch tập từ AI chỉ mang tính chất tham khảo cá nhân, không đảm bảo chính xác tuyệt đối và không thay thế tư vấn huấn luyện viên/bác sĩ.',
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
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF64748B)),
                      const SizedBox(width: 10),
                      Text('Bắt đầu:', style: GoogleFonts.workSans(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF334155))),
                      const Spacer(),
                      ChoiceChip(
                        label: const Text('Hôm nay'),
                        selected: !_startTomorrow,
                        onSelected: (selected) {
                          if (selected && _startTomorrow) {
                            _toggleStartDate(false);
                          }
                        },
                        selectedColor: AppTheme.primary,
                        labelStyle: TextStyle(color: !_startTomorrow ? Colors.white : const Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Ngày mai'),
                        selected: _startTomorrow,
                        onSelected: (selected) {
                          if (selected && !_startTomorrow) {
                            _toggleStartDate(true);
                          }
                        },
                        selectedColor: AppTheme.primary,
                        labelStyle: TextStyle(color: _startTomorrow ? Colors.white : const Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Lịch tập Ngày $dateString',
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
                        '${currentDay.workoutItems.length} bài tập',
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
                if (currentDay.note != null && currentDay.note!.isNotEmpty) _buildDailyOverviewCard(currentDay.note!),
                const SizedBox(height: 20),
                if (currentDay.workoutItems.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          Icon(Icons.hotel_outlined, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text(
                            'Ngày nghỉ ngơi / Phục hồi cơ bắp',
                            style: AppTheme.semiboldStyle.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...currentDay.workoutItems.map((item) => _buildWorkoutItemCard(item)),
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
                  'Gợi ý Lịch tập AI',
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

  Widget _buildWorkoutItemCard(DailyWorkoutItemModel item) {
    final imageUrl = 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?q=80&w=600';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(imageUrl, width: 60, height: 60, fit: BoxFit.cover),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.exerciseNameSnapshot.isNotEmpty
                        ? item.exerciseNameSnapshot
                        : (item.notes != null && item.notes!.isNotEmpty ? item.notes! : 'Bài tập tự do'),
                    style: GoogleFonts.workSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _buildParamString(item),
                    style: AppTheme.bodyStyle.copyWith(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.local_fire_department, color: Colors.orange, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${item.caloriesBurnedSnapshot.toStringAsFixed(0)} kcal',
                        style: GoogleFonts.workSans(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF475569),
                        ),
                      ),
                      if (item.notes != null && item.notes!.isNotEmpty) ...[
                        const SizedBox(width: 16),
                        const Icon(Icons.description_outlined, color: Colors.blue, size: 14),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.notes!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.bodyStyle.copyWith(fontSize: 12, color: Colors.blue),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildParamString(DailyWorkoutItemModel item) {
    final sb = StringBuffer();
    if (item.setsSnapshot != null && item.setsSnapshot! > 0) {
      sb.write('${item.setsSnapshot} sets');
    }
    if (item.repsSnapshot != null && item.repsSnapshot! > 0) {
      if (sb.isNotEmpty) sb.write(' • ');
      sb.write('${item.repsSnapshot} reps');
    }
    if (item.weightKgSnapshot != null && item.weightKgSnapshot! > 0) {
      if (sb.isNotEmpty) sb.write(' • ');
      sb.write('${item.weightKgSnapshot}kg');
    }
    if (item.durationMinutesSnapshot != null && item.durationMinutesSnapshot! > 0) {
      if (sb.isNotEmpty) sb.write(' • ');
      sb.write('${item.durationMinutesSnapshot}m');
    }
    if (item.distanceKmSnapshot != null && item.distanceKmSnapshot! > 0) {
      if (sb.isNotEmpty) sb.write(' • ');
      sb.write('${item.distanceKmSnapshot}km');
    }
    return sb.toString();
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
        boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: OutlinedButton(
              onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF64748B),
                side: BorderSide(color: Colors.grey.shade300),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Hủy'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _applyWorkoutPlan,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF7A30),
                padding: const EdgeInsets.symmetric(vertical: 16),
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
                  : const Text('Áp dụng lịch tập'),
            ),
          ),
        ],
      ),
    );
  }
}
