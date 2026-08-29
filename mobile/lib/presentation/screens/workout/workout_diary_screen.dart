import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/presentation/bloc/workout/workout_diary_cubit.dart';
import 'package:mobile/presentation/bloc/workout/workout_diary_state.dart';
import 'package:core_shared/core_shared.dart';
import 'exercise_timer_screen.dart';
import 'widgets/sheets/add_exercise_bottom_sheet.dart';
import 'widgets/sections/calender_workout.dart';
import 'package:mobile/presentation/widgets/error_fallback_card.dart';

class WorkoutDiaryScreen extends StatefulWidget {
  const WorkoutDiaryScreen({super.key, this.initialDate});

  final DateTime? initialDate;

  @override
  State<WorkoutDiaryScreen> createState() => _WorkoutDiaryScreenState();
}

class _WorkoutDiaryScreenState extends State<WorkoutDiaryScreen> {
  final weekdays = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selectedDate = widget.initialDate ?? DateTime.now();
      context.read<WorkoutDiaryCubit>().selectDate(selectedDate);

      // Fetch weekly workouts starting from Monday
      final monday = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
      final sunday = monday.add(const Duration(days: 6));
      context.read<WorkoutDiaryCubit>().fetchWeeklyWorkouts(monday, sunday);
    });
  }

  bool isToday(DateTime date) {
    final now = DateTime.now();
    return now.year == date.year && now.month == date.month && now.day == date.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocBuilder<WorkoutDiaryCubit, WorkoutDiaryState>(
        builder: (context, state) {
          final selectedDate = state.selectedDate ?? DateTime.now();
          final monday = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
          final weekDays = List.generate(7, (index) => monday.add(Duration(days: index)));

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dark Header
              _buildDarkHeader(state, weekDays),

              // Summary Stats Card
              _buildSummaryStats(state),

              // Note box
              _buildNoteBox(state, selectedDate),

              // Exercise List Section Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Text(
                  'Planned Exercises',
                  style: AppTheme.headlineStyle.copyWith(
                    fontSize: 18,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Exercise List
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: _buildExerciseList(state, selectedDate),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: BlocBuilder<WorkoutDiaryCubit, WorkoutDiaryState>(
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
                builder: (context) => AddExerciseBottomSheet(selectedDate: selectedDate),
              );
            },
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildDarkHeader(WorkoutDiaryState state, List<DateTime> weekDays) {
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
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                  ),
                ),
                Text(
                  'Workout Schedule',
                  style: GoogleFonts.workSans(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const CalenderWorkout()),
                    );
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.calendar_today, color: Colors.white, size: 20),
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
                    context.read<WorkoutDiaryCubit>().selectDate(day);
                  },
                  child: Container(
                    width: 60,
                    margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFFF7A30) : Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: today && !isSelected ? Border.all(color: const Color(0xFFFF7A30).withValues(alpha: 0.5)) : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          dayName,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.4),
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
                            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.2),
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

  Widget _buildSummaryStats(WorkoutDiaryState state) {
    if (state.selectedDate == null) return const SizedBox.shrink();

    final dateStr = DateFormat('yyyy-MM-dd').format(state.selectedDate!);
    final dailyWorkout = state.dailyWorkouts[dateStr];

    final planned = dailyWorkout?.totalCaloriesPlanned ?? 0.0;
    final burned = dailyWorkout?.totalCaloriesBurned ?? 0.0;
    final completed = dailyWorkout?.workoutItems.where((i) => i.isCompleted).length ?? 0;
    final total = dailyWorkout?.workoutItems.length ?? 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Planned', '${planned.toStringAsFixed(0)} kcal', Icons.flag_outlined, Colors.blue),
          _buildStatItem('Burned', '${burned.toStringAsFixed(0)} kcal', Icons.local_fire_department, Colors.red),
          _buildStatItem('Completed', '$completed/$total Done', Icons.check_circle_outline, Colors.green),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 15, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildNoteBox(WorkoutDiaryState state, DateTime selectedDate) {
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
    final dailyWorkout = state.dailyWorkouts[dateStr];
    final note = dailyWorkout?.note ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFECE0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD5C2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline, color: Color(0xFFFF7A30), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              note.isNotEmpty ? note : 'Tip: Tap "+" below to schedule workouts. Track your stats by completing scheduled items.',
              style: TextStyle(
                color: const Color(0xFF8F431F),
                fontSize: 12,
                height: 1.3,
                fontStyle: note.isEmpty ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_note, color: Color(0xFFFF7A30)),
            onPressed: () => _showEditNoteDialog(context, note, selectedDate),
          ),
        ],
      ),
    );
  }

  void _showEditNoteDialog(BuildContext context, String currentNote, DateTime date) {
    final controller = TextEditingController(text: currentNote);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Daily Workout Note'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Add workout plan notes or instructions...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<WorkoutDiaryCubit>().updateDailyNote(date, controller.text.trim());
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildExerciseList(WorkoutDiaryState state, DateTime selectedDate) {
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
    final dailyWorkout = state.dailyWorkouts[dateStr];

    if (dailyWorkout == null && state.status == WorkoutDiaryStatus.loading) {
      return const Padding(
        padding: EdgeInsets.all(40.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.status == WorkoutDiaryStatus.failure) {
      return ErrorFallbackCard(
        title: 'Không thể tải nhật ký tập luyện',
        message: state.errorMessage ?? 'Đã có lỗi xảy ra khi kết nối máy chủ.',
        onRetry: () => context.read<WorkoutDiaryCubit>().fetchDailyWorkout(selectedDate),
      );
    }

    final items = dailyWorkout?.workoutItems ?? [];

    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40.0),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.fitness_center, size: 54, color: Colors.grey[300]),
              const SizedBox(height: 12),
              Text(
                'Chưa có bài tập nào được lên lịch cho ngày hôm nay.',
                style: AppTheme.bodyStyle.copyWith(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];

        final imageUrl = 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?q=80&w=600';

        return GestureDetector(
          onTap: () {
            final exercise = ExerciseModel(
              id: item.exerciseId ?? '',
              code: '',
              name: item.exerciseNameSnapshot,
              defaultDuration: item.durationMinutesSnapshot ?? 10,
              durationUnit: 'min',
              thumbnailUrl: imageUrl,
            );
            Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(
                builder: (context) => ExerciseTimerScreen(
                  exercise: exercise,
                  dailyWorkoutItemId: item.id,
                  selectedDate: selectedDate,
                  sets: item.setsSnapshot,
                  reps: item.repsSnapshot,
                  restSeconds: item.restSecondsSnapshot,
                ),
              ),
            );
          },
          child: Container(
            height: 140,
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withValues(alpha: 0.15), Colors.black.withValues(alpha: 0.75)],
                ),
              ),
              child: Row(
                children: [
                  // Completed Toggle Button
                  GestureDetector(
                    onTap: () {
                      if (item.id != null) {
                        context.read<WorkoutDiaryCubit>().toggleExerciseStatus(item.id!, !item.isCompleted, selectedDate);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: item.isCompleted ? Colors.green : Colors.black.withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(item.isCompleted ? Icons.check : Icons.radio_button_unchecked, color: Colors.white, size: 24),
                    ),
                  ),
                  const SizedBox(width: 16),
  
                  // Text details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.exerciseNameSnapshot,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        // Parameter stats
                        Text(
                          _buildParamString(item),
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.local_fire_department, color: Colors.orange, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${item.caloriesBurnedSnapshot.toStringAsFixed(0)} kcal',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
  
                  // More Options Vert icon
                  GestureDetector(
                    onTap: () => _showItemOptions(context, item, selectedDate),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.35), shape: BoxShape.circle),
                      child: const Icon(Icons.more_vert, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
      sb.write('Tập: ${item.durationMinutesSnapshot}m');
    }
    if (item.restSecondsSnapshot != null && item.restSecondsSnapshot! > 0) {
      if (sb.isNotEmpty) sb.write(' • ');
      sb.write('Nghỉ: ${item.restSecondsSnapshot}s');
    }
    if (item.distanceKmSnapshot != null && item.distanceKmSnapshot! > 0) {
      if (sb.isNotEmpty) sb.write(' • ');
      sb.write('${item.distanceKmSnapshot}km');
    }
    if (item.notes != null && item.notes!.isNotEmpty) {
      if (sb.isNotEmpty) sb.write('\n');
      sb.write('Note: ${item.notes}');
    }
    return sb.toString();
  }

  void _showItemOptions(BuildContext context, DailyWorkoutItemModel item, DateTime date) {
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
                  item.exerciseNameSnapshot,
                  style: AppTheme.semiboldStyle.copyWith(fontSize: 16),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: Colors.blue),
                title: const Text('Chỉnh sửa thông số', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.of(context).pop();
                  _showEditFormBottomSheet(item, date);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Xóa khỏi lịch', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.of(context).pop();
                  context.read<WorkoutDiaryCubit>().removeExerciseFromDiary(item.id ?? '', date);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Removed ${item.exerciseNameSnapshot} from diary'),
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

  void _showEditFormBottomSheet(DailyWorkoutItemModel item, DateTime date) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _EditExerciseForm(item: item, selectedDate: date);
      },
    );
  }
}

class _EditExerciseForm extends StatefulWidget {
  final DailyWorkoutItemModel item;
  final DateTime selectedDate;

  const _EditExerciseForm({
    required this.item,
    required this.selectedDate,
  });

  @override
  State<_EditExerciseForm> createState() => _EditExerciseFormState();
}

class _EditExerciseFormState extends State<_EditExerciseForm> {
  int _sets = 3;
  int _reps = 12;
  double _weight = 0.0;
  int _duration = 10;
  int _rest = 60;
  double _distance = 0.0;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _sets = widget.item.setsSnapshot ?? 3;
    _reps = widget.item.repsSnapshot ?? 12;
    _weight = widget.item.weightKgSnapshot ?? 0.0;
    _duration = widget.item.durationMinutesSnapshot ?? 10;
    _rest = widget.item.restSecondsSnapshot ?? 60;
    _distance = widget.item.distanceKmSnapshot ?? 0.0;
    _notesController.text = widget.item.notes ?? '';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.item.exerciseNameSnapshot;
    final isCardio = widget.item.setsSnapshot == null;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Chỉnh sửa thông số', style: AppTheme.headlineStyle.copyWith(fontSize: 20)),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(name, style: AppTheme.semiboldStyle.copyWith(color: AppTheme.textSecondary)),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  if (!isCardio) ...[
                    Row(
                      children: [
                        Expanded(
                          child: _buildNumberSpinner(
                            label: 'Sets',
                            value: _sets,
                            onChanged: (val) => setState(() => _sets = val),
                            min: 1,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildNumberSpinner(
                            label: 'Reps',
                            value: _reps,
                            onChanged: (val) => setState(() => _reps = val),
                            min: 0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildDoubleSpinner(
                      label: 'Weight (kg)',
                      value: _weight,
                      onChanged: (val) => setState(() => _weight = val),
                      step: 2.5,
                      suffix: 'kg',
                    ),
                    const SizedBox(height: 20),
                    _buildNumberSpinner(
                      label: 'Rest Time (seconds)',
                      value: _rest,
                      onChanged: (val) => setState(() => _rest = val),
                      min: 0,
                      step: 15,
                      suffix: 's',
                    ),
                    const SizedBox(height: 20),
                  ],

                  Row(
                    children: [
                      Expanded(
                        child: _buildNumberSpinner(
                          label: 'Duration (minutes)',
                          value: _duration,
                          onChanged: (val) => setState(() => _duration = val),
                          min: 1,
                          step: 5,
                          suffix: 'm',
                        ),
                      ),
                      if (isCardio || widget.item.isCustom) ...[
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDoubleSpinner(
                            label: 'Distance (km)',
                            value: _distance,
                            onChanged: (val) => setState(() => _distance = val),
                            step: 0.5,
                            suffix: 'km',
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Notes field
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Notes / Tips', style: AppTheme.semiboldStyle.copyWith(fontSize: 15)),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'e.g., Focus on slow reps',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final itemData = {
                          'sets': isCardio ? null : _sets,
                          'reps': isCardio ? null : _reps,
                          'weightKg': isCardio ? null : _weight,
                          'restSeconds': isCardio ? null : _rest,
                          'durationMinutes': _duration,
                          'distanceKm': (isCardio || widget.item.isCustom) && _distance > 0 ? _distance : null,
                          'notes': _notesController.text.trim(),
                        };

                        final messenger = ScaffoldMessenger.of(context);
                        final navigator = Navigator.of(context);

                        await context.read<WorkoutDiaryCubit>().updateExerciseInDiary(
                          widget.item.id!,
                          itemData,
                          widget.selectedDate,
                        );

                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Updated exercise settings'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        navigator.pop();
                      },
                      child: const Text('Cập nhật'),
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

  Widget _buildNumberSpinner({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
    int min = 0,
    int step = 1,
    String suffix = '',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.semiboldStyle.copyWith(fontSize: 14, color: AppTheme.textSecondary)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  if (value > min) {
                    onChanged(value - step);
                  }
                },
                icon: const Icon(Icons.remove, size: 18),
              ),
              Text(
                '$value$suffix',
                style: AppTheme.semiboldStyle.copyWith(fontSize: 16),
              ),
              IconButton(
                onPressed: () {
                  onChanged(value + step);
                },
                icon: const Icon(Icons.add, size: 18),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDoubleSpinner({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
    double min = 0.0,
    double step = 1.0,
    String suffix = '',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.semiboldStyle.copyWith(fontSize: 14, color: AppTheme.textSecondary)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  if (value > min) {
                    onChanged(value - step);
                  }
                },
                icon: const Icon(Icons.remove, size: 18),
              ),
              Text(
                '${value.toStringAsFixed(value % 1 == 0 ? 0 : 1)}$suffix',
                style: AppTheme.semiboldStyle.copyWith(fontSize: 16),
              ),
              IconButton(
                onPressed: () {
                  onChanged(value + step);
                },
                icon: const Icon(Icons.add, size: 18),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
