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

  @override
  void initState() {
    super.initState();
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
      final jsonString = await userRepository.getAiWorkoutSuggestion(userId, days: widget.days);
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage != null
          ? _buildErrorState()
          : _buildContentState(),
      bottomNavigationBar: !_isLoading && _errorMessage == null ? _buildBottomBar() : null,
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 20),
            Text(
              'Có lỗi xảy ra',
              style: GoogleFonts.workSans(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF131517)),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Không thể tải gợi ý lịch tập.',
              style: AppTheme.bodyStyle.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchAiSuggestion,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF7A30),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Quay lại')),
          ],
        ),
      ),
    );
  }

  Widget _buildContentState() {
    final currentDay = _suggestions[_selectedDayIndex];
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
                const SizedBox(width: 44),
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
                    item.exerciseNameSnapshot,
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
