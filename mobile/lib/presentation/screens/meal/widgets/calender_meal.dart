import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/routes/app_routes.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/presentation/bloc/meal/meal_cubit.dart';
import 'package:mobile/presentation/bloc/meal/meal_state.dart';
import 'package:intl/intl.dart';

class CalenderMeal extends StatefulWidget {
  const CalenderMeal({super.key});

  @override
  State<CalenderMeal> createState() => _CalenderMealState();
}

class _CalenderMealState extends State<CalenderMeal> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchMonthData(_focusedDay);
    });
  }

  void _fetchMonthData(DateTime date) {
    final start = DateTime(date.year, date.month - 1, 20);
    final end = DateTime(date.year, date.month + 1, 10);
    context.read<MealCubit>().fetchWeeklyEating(start, end);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Meal Calendar',
          style: GoogleFonts.workSans(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF131517),
        elevation: 0,
        centerTitle: true,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          ),
        ),
      ),
      backgroundColor: const Color(0xFFFAFAFA),
      body: BlocBuilder<MealCubit, MealState>(
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              children: [
                TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2035, 12, 31),
                  focusedDay: _focusedDay,

                  calendarFormat: CalendarFormat.month,

                  selectedDayPredicate: (day) {
                    return isSameDay(_selectedDay, day);
                  },

                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                    Navigator.of(context).pushNamed(AppRoutes.mealPlan, arguments: selectedDay);
                  },

                  onPageChanged: (focusedDay) {
                    setState(() {
                      _focusedDay = focusedDay;
                    });
                    _fetchMonthData(focusedDay);
                  },

                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: GoogleFonts.workSans(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF131517),
                    ),
                    leftChevronIcon: const Icon(Icons.chevron_left, color: Color(0xFF131517), size: 24),
                    rightChevronIcon: const Icon(Icons.chevron_right, color: Color(0xFF131517), size: 24),
                    headerPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),

                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: GoogleFonts.workSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF666666),
                    ),
                    weekendStyle: GoogleFonts.workSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFFF7A30),
                    ),
                  ),

                  calendarStyle: CalendarStyle(
                    defaultTextStyle: GoogleFonts.workSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF333333),
                    ),
                    weekendTextStyle: GoogleFonts.workSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF333333),
                    ),
                    outsideTextStyle: GoogleFonts.workSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFFBBBBBB),
                    ),
                    selectedTextStyle: GoogleFonts.workSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    todayTextStyle: GoogleFonts.workSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: const Color(0xFFFF7A30),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF7A30).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    todayDecoration: BoxDecoration(
                      color: const Color(0xFFFF7A30).withValues(alpha: 0.8),
                      shape: BoxShape.circle,
                    ),
                    defaultDecoration: const BoxDecoration(color: Colors.transparent, shape: BoxShape.circle),
                    weekendDecoration: const BoxDecoration(color: Colors.transparent, shape: BoxShape.circle),
                    outsideDecoration: const BoxDecoration(color: Colors.transparent, shape: BoxShape.circle),
                    cellMargin: const EdgeInsets.all(8),
                    cellPadding: const EdgeInsets.all(8),
                  ),
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, day, events) {
                      final dateStr = DateFormat('yyyy-MM-dd').format(day);
                      final dailyEating = state.dailyEatings[dateStr];

                      if (dailyEating == null || dailyEating.mealSlots.isEmpty) return null;

                      bool hasItems = false;
                      bool allEaten = true;

                      for (var slot in dailyEating.mealSlots) {
                        if (slot.items.isNotEmpty) hasItems = true;
                        for (var item in slot.items) {
                          if (!item.isEaten) {
                            allEaten = false;
                          }
                        }
                      }

                      if (!hasItems) return null;

                      return Positioned(
                        bottom: 8,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: allEaten ? Colors.green : const Color(0xFFFF7A30),
                          ),
                        ),
                      );
                    },
                  ),
                  startingDayOfWeek: StartingDayOfWeek.monday,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem(const Color(0xFFFF7A30), 'Planned'),
                    const SizedBox(width: 24),
                    _buildLegendItem(Colors.green, 'Completed'),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.workSans(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF666666)),
        ),
      ],
    );
  }
}
