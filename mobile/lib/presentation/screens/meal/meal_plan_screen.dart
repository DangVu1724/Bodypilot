import 'package:core_shared/models/daily_eating_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/utils/category_image_helper.dart';
import 'package:mobile/presentation/bloc/meal/meal_cubit.dart';
import 'package:mobile/presentation/bloc/meal/meal_state.dart';
import 'package:mobile/presentation/screens/meal/widgets/sections/calender_meal.dart';

import 'widgets/sheets/add_meal_bottom_sheet.dart';
import 'widgets/sheets/smart_swap_bottom_sheet.dart';
import 'package:mobile/presentation/widgets/error_fallback_card.dart';

class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({super.key, this.initialDate});

  final DateTime? initialDate;

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  final weekdays = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  MealType _selectedMealType = MealType.BREAKFAST;

  final List<MealType> _mealTypes = [MealType.BREAKFAST, MealType.LUNCH, MealType.DINNER];

  @override
  void initState() {
    super.initState();
    // Tự động chọn ngày đã chọn từ lịch nếu có, hoặc ngày hôm nay nếu không.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selectedDate = widget.initialDate ?? DateTime.now();
      context.read<MealCubit>().selectDate(selectedDate);

      final monday = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
      final sunday = monday.add(const Duration(days: 6));
      context.read<MealCubit>().fetchWeeklyEating(monday, sunday);
    });
  }

  bool isToday(DateTime date) {
    final now = DateTime.now();
    return now.year == date.year && now.month == date.month && now.day == date.day;
  }

  String _getMealTypeName(MealType type) {
    switch (type) {
      case MealType.BREAKFAST:
        return 'Breakfast';
      case MealType.LUNCH:
        return 'Lunch';
      case MealType.DINNER:
        return 'Dinner';
      case MealType.SNACK:
        return 'Snack';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocBuilder<MealCubit, MealState>(
        builder: (context, state) {
          final selectedDate = state.selectedDate ?? DateTime.now();
          final monday = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
          final weekDays = List.generate(7, (index) => monday.add(Duration(days: index)));

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDarkHeader(state, weekDays),

              _buildMealTypeSelector(),

              _buildSectionTitle(state),

              // Expanded Meal List
              Expanded(
                child: SingleChildScrollView(physics: const BouncingScrollPhysics(), child: _buildMealList(state)),
              ),
            ],
          );
        },
      ),
      floatingActionButton: BlocBuilder<MealCubit, MealState>(
        builder: (context, state) {
          return FloatingActionButton(
            backgroundColor: const Color(0xFFFF7A30),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            onPressed: () {
              final selectedDate = state.selectedDate ?? DateTime.now();

              showModalBottomSheet(
                context: context,
                useRootNavigator: true,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) =>
                    AddMealBottomSheet(selectedDate: selectedDate, selectedMealType: _selectedMealType),
              );
            },
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildDarkHeader(MealState state, List<DateTime> weekDays) {
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
                // Custom Back button
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

                // Title
                Text(
                  'My Meals',
                  style: GoogleFonts.workSans(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),

                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const CalenderMeal()));
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.calendar_today, color: Colors.white, size: 22),
                  ),
                ),
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
              itemCount: weekDays.length,
              itemBuilder: (context, index) {
                final day = weekDays[index];
                final isSelected =
                    state.selectedDate != null &&
                    day.year == state.selectedDate!.year &&
                    day.month == state.selectedDate!.month &&
                    day.day == state.selectedDate!.day;
                final today = isToday(day);

                final dayName = weekdays[day.weekday - 1];
                final dayNum = day.day.toString();

                return GestureDetector(
                  onTap: () {
                    context.read<MealCubit>().selectDate(day);
                  },
                  child: Container(
                    width: 60,
                    margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFFF7A30) : Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: today && !isSelected ? Border.all(color: const Color(0xFFFF7A30).withOpacity(0.5)) : null,
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

  Widget _buildMealTypeSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        children: _mealTypes.map((type) {
          final isSelected = _selectedMealType == type;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedMealType = type;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF131517) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                _getMealTypeName(type),
                style: AppTheme.semiboldStyle.copyWith(
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionTitle(MealState state) {
    MealSlotModel? slot;
    if (state.selectedDate != null) {
      final selectedDateStr = DateFormat('yyyy-MM-dd').format(state.selectedDate!);
      final dailyEating = state.dailyEatings[selectedDateStr];
      if (dailyEating != null) {
        try {
          slot = dailyEating.mealSlots.firstWhere((s) => s.mealType == _selectedMealType);
          if (slot.items.isEmpty) slot = null;
        } catch (_) {
          slot = null;
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'All Meals',
            style: AppTheme.headlineStyle.copyWith(
              fontSize: 18,
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (slot != null && slot.id != null)
            GestureDetector(
              onTap: () {
                context.read<MealCubit>().toggleMealSlotStatus(slot!.id!, !slot.isEaten, state.selectedDate!);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: slot.isEaten ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      slot.isEaten ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: slot.isEaten ? Colors.green : Colors.grey,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      slot.isEaten ? 'Eaten' : 'Mark as eaten',
                      style: TextStyle(
                        color: slot.isEaten ? Colors.green : Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMealList(MealState state) {
    if (state.selectedDate == null) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(child: Text('Vui lòng chọn ngày')),
      );
    }

    final selectedDateStr = DateFormat('yyyy-MM-dd').format(state.selectedDate!);
    final dailyEating = state.dailyEatings[selectedDateStr];

    // Đang tải dữ liệu của ngày đó
    if (dailyEating == null && state.status == MealStatus.loading) {
      return const Padding(
        padding: EdgeInsets.all(40.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Bị lỗi khi tải
    if (state.status == MealStatus.failure) {
      return ErrorFallbackCard(
        title: 'Không thể tải nhật ký thực đơn',
        message: state.errorMessage ?? 'Đã xảy ra lỗi khi kết nối máy chủ.',
        onRetry: () => context.read<MealCubit>().fetchDailyEating(state.selectedDate!),
      );
    }

    // Find slots matching active tab
    final slot = dailyEating?.mealSlots.firstWhere(
      (s) => s.mealType == _selectedMealType,
      orElse: () => MealSlotModel(mealType: _selectedMealType, items: []),
    );

    // Không có dữ liệu
    if (slot == null || slot.items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40.0),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.restaurant, size: 54, color: Colors.grey[300]),
              const SizedBox(height: 12),
              Text(
                'No meals added for ${_getMealTypeName(_selectedMealType)} yet.',
                style: AppTheme.bodyStyle.copyWith(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    // Hiển thị danh sách bữa ăn
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      itemCount: slot.items.length,
      itemBuilder: (context, index) {
        final item = slot.items[index];

        final totalMacros = item.proteinSnapshot + item.fatSnapshot + item.carbsSnapshot;
        final proteinRatio = totalMacros > 0 ? item.proteinSnapshot / totalMacros : 0.0;
        final fatRatio = totalMacros > 0 ? item.fatSnapshot / totalMacros : 0.0;
        final carbsRatio = totalMacros > 0 ? item.carbsSnapshot / totalMacros : 0.0;

        return Container(
          height: 190,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            image: DecorationImage(
              image: getFoodImageProvider(item.imageUrlSnapshot, null, item.foodNameSnapshot),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withOpacity(0.15), Colors.black.withOpacity(0.75)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (item.id != null) {
                          context.read<MealCubit>().toggleMealItemStatus(item.id!, !item.isEaten, state.selectedDate!);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: item.isEaten ? Colors.green : Colors.black.withOpacity(0.35),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          item.isEaten ? Icons.check : Icons.check_circle_outline,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        if (item.foodId != null) {
                          SmartSwapBottomSheet.show(
                            context,
                            foodId: item.foodId!,
                            currentFoodName: item.foodNameSnapshot,
                            currentServingQuantity: item.servingQuantity,
                            onFoodSwapped: (candidate) {
                              if (item.id != null) {
                                context.read<MealCubit>().removeFoodFromDiary(item.id!, state.selectedDate!);
                              }
                              context.read<MealCubit>().addFoodToDiary(
                                date: state.selectedDate!,
                                mealType: slot.mealType,
                                itemData: {
                                  'foodId': candidate.foodId,
                                  'servingQuantity': candidate.recommendedServingQuantity,
                                },
                              );
                            },
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(color: Colors.black.withOpacity(0.35), shape: BoxShape.circle),
                        child: const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showMealItemOptions(context, item, state.selectedDate!),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.black.withOpacity(0.35), shape: BoxShape.circle),
                        child: const Icon(Icons.more_vert, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
                const Spacer(),

                // Meal item Name
                Text(
                  item.foodNameSnapshot,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // Kcal & Serving quantity
                Row(
                  children: [
                    const Icon(Icons.local_fire_department, color: Colors.orange, size: 15),
                    const SizedBox(width: 4),
                    Text(
                      '${item.caloriesSnapshot.toStringAsFixed(0)} kcal',
                      style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${item.servingQuantity.toStringAsFixed(0)} ${item.servingUnitSnapshot ?? 'g'}',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Macro progress row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMacroIndicator('${item.proteinSnapshot.toStringAsFixed(0)}g', 'Protein', proteinRatio),
                    _buildMacroIndicator('${item.fatSnapshot.toStringAsFixed(0)}g', 'Fats', fatRatio),
                    _buildMacroIndicator('${item.carbsSnapshot.toStringAsFixed(0)}g', 'Carbs', carbsRatio),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMacroIndicator(String value, String label, double percentage) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 15,
          height: 15,
          child: CircularProgressIndicator(
            value: percentage.clamp(0.0, 1.0),
            strokeWidth: 2.5,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$value $label',
          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  void _showMealItemOptions(BuildContext context, MealItemModel item, DateTime date) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Text(
                  item.foodNameSnapshot.isNotEmpty ? item.foodNameSnapshot : 'Meal item',
                  style: AppTheme.semiboldStyle.copyWith(fontSize: 16),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.swap_horizontal_circle_outlined, color: Color(0xFFFF7A30)),
                title: const Text(
                  'Đổi món tương đương (Smart Swap)',
                  style: TextStyle(color: Color(0xFFFF7A30), fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  if (item.foodId != null) {
                    SmartSwapBottomSheet.show(
                      context,
                      foodId: item.foodId!,
                      currentFoodName: item.foodNameSnapshot,
                      currentServingQuantity: item.servingQuantity,
                      onFoodSwapped: (candidate) {
                        if (item.id != null) {
                          context.read<MealCubit>().removeFoodFromDiary(item.id!, date);
                        }
                        context.read<MealCubit>().addFoodToDiary(
                          date: date,
                          mealType: _selectedMealType,
                          itemData: {
                            'foodId': candidate.foodId,
                            'servingQuantity': candidate.recommendedServingQuantity,
                          },
                        );
                      },
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'Delete from diary',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  context.read<MealCubit>().removeFoodFromDiary(item.id ?? '', date);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Removed ${item.foodNameSnapshot.isNotEmpty ? item.foodNameSnapshot : 'meal item'} from diary',
                      ),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel_outlined),
                title: const Text('Cancel'),
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      },
    );
  }
}
