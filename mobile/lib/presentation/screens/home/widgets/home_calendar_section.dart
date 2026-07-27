import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mobile/presentation/bloc/workout/workout_diary_cubit.dart';
import 'package:mobile/presentation/bloc/meal/meal_cubit.dart';

class HomeCalendarSection extends StatefulWidget {
  const HomeCalendarSection({super.key});

  @override
  State<HomeCalendarSection> createState() => _HomeCalendarSectionState();
}

class _HomeCalendarSectionState extends State<HomeCalendarSection> {
  late List<DateTime> _weekDays;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateUtils.dateOnly(now);
    
    // Calculate week days (Monday to Sunday)
    final monday = now.subtract(Duration(days: now.weekday - 1));
    _weekDays = List.generate(7, (index) => DateUtils.dateOnly(monday.add(Duration(days: index))));

    // Fetch data for the week
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mondayDate = _weekDays.first;
      final sundayDate = _weekDays.last;
      context.read<WorkoutDiaryCubit>().fetchWeeklyWorkouts(mondayDate, sundayDate);
      context.read<MealCubit>().fetchWeeklyEating(mondayDate, sundayDate);
      
      // Also set the initial selected date in the cubits
      context.read<WorkoutDiaryCubit>().selectDate(_selectedDate);
      context.read<MealCubit>().selectDate(_selectedDate);
    });
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    context.read<WorkoutDiaryCubit>().selectDate(date);
    context.read<MealCubit>().selectDate(date);
  }

  @override
  Widget build(BuildContext context) {
    final workoutState = context.watch<WorkoutDiaryCubit>().state;
    final mealState = context.watch<MealCubit>().state;
    
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    
    final dailyWorkout = workoutState.dailyWorkouts[dateStr];
    final dailyEating = mealState.dailyEatings[dateStr];
    
    final caloriesBurned = dailyWorkout?.totalCaloriesBurned ?? 0.0;
    final caloriesConsumed = dailyEating?.totalCaloriesEaten ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCalendarStrip(),
        _buildCalorieSummary(caloriesConsumed, caloriesBurned),
      ],
    );
  }

  Widget _buildCalendarStrip() {
    final weekdayNames = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    return SizedBox(
      height: 72,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _weekDays.length,
        itemBuilder: (context, index) {
          final dayDate = _weekDays[index];
          final isSelected = DateUtils.isSameDay(dayDate, _selectedDate);
          final isToday = DateUtils.isSameDay(dayDate, DateTime.now());
          
          final dateText = dayDate.day.toString();
          final dayName = weekdayNames[dayDate.weekday - 1];
          
          return GestureDetector(
            onTap: () => _onDateSelected(dayDate),
            child: Container(
              width: 52,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFF97316) : Colors.white.withOpacity(0.45),
                borderRadius: BorderRadius.circular(18),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFFF97316).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : null,
                border: isToday && !isSelected
                    ? Border.all(color: const Color(0xFFF97316).withOpacity(0.5), width: 1.5)
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dateText,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dayName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? Colors.white.withOpacity(0.85) : const Color(0xFF64748B),
                    ),
                  ),
                  if (isSelected) ...[
                    const SizedBox(height: 4),
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    )
                  ]
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCalorieSummary(double consumed, double burned) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Row(
        children: [
          // Consumed Calorie Card
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF97316).withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.restaurant_rounded,
                    color: Color(0xFFF97316),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Calo nạp vào',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${consumed.toStringAsFixed(0)} kcal',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Divider
          Container(
            height: 36,
            width: 1,
            color: const Color(0xFFCBD5E1),
            margin: const EdgeInsets.symmetric(horizontal: 8),
          ),

          // Burned Calorie Card
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF84CC16).withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_fire_department_rounded,
                    color: Color(0xFF84CC16),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Calo tiêu hao',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${burned.toStringAsFixed(0)} kcal',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
