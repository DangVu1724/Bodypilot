import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/data/services/token_service.dart';
import 'package:mobile/data/repositories/user_repository.dart';
import 'package:mobile/data/repositories/nutrition_diary_repository.dart';
import 'package:core_shared/models/daily_eating_model.dart';

class AiMealSuggestionScreen extends StatefulWidget {
  const AiMealSuggestionScreen({super.key});

  @override
  State<AiMealSuggestionScreen> createState() => _AiMealSuggestionScreenState();
}

class _AiMealSuggestionScreenState extends State<AiMealSuggestionScreen> {
  List<DailyEatingModel> _suggestions = [];
  int _selectedDayIndex = 0;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isSaving = false;

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

  @override
  void initState() {
    super.initState();
    _fetchAiSuggestion();
  }

  Future<void> _fetchAiSuggestion() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final userId = TokenService.getUserId();
      if (userId == null) {
        throw Exception("Không tìm thấy thông tin tài khoản người dùng.");
      }
      final jsonString = await userRepository.getAiDietSuggestion(userId);
      final List<dynamic> decoded = jsonDecode(jsonString) as List<dynamic>;
      final suggestions = decoded.map((e) => DailyEatingModel.fromJson(e as Map<String, dynamic>)).toList();
      setState(() {
        _suggestions = suggestions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll("Exception: ", "");
        _isLoading = false;
      });
    }
  }

  Future<void> _applyMealPlan() async {
    if (_suggestions.isEmpty) return;
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
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                strokeWidth: 4.5,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF7A30)),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'AI đang thiết lập thực đơn...',
              style: GoogleFonts.workSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF131517),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tính toán dinh dưỡng, phân bổ năng lượng phù hợp với cơ thể bạn.',
              style: AppTheme.bodyStyle.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
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
              style: GoogleFonts.workSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF131517),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Không thể tải gợi ý thực đơn.',
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
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Quay lại'),
            ),
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
    final displayImage = (item.imageUrlSnapshot ?? '').isNotEmpty
        ? item.imageUrlSnapshot!
        : 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?q=80&w=600';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Food Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              displayImage,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 50,
                height: 50,
                color: Colors.grey.shade100,
                child: const Icon(Icons.restaurant, color: Colors.grey),
              ),
            ),
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
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
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
              onPressed: _isSaving ? null : _applyMealPlan,
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
                  : const Text('Áp dụng thực đơn'),
            ),
          ),
        ],
      ),
    );
  }
}
