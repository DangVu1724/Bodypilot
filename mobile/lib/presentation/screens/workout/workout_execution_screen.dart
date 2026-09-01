import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:core_shared/models/workout_session_model.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/utils/calorie_calculator.dart';
import 'workout_summary_screen.dart';

class WorkoutExecutionScreen extends StatefulWidget {
  final WorkoutSessionModel session;

  const WorkoutExecutionScreen({
    super.key,
    required this.session,
  });

  @override
  State<WorkoutExecutionScreen> createState() => _WorkoutExecutionScreenState();
}

class _WorkoutExecutionScreenState extends State<WorkoutExecutionScreen> {
  // Workout Active Duration Timer
  int _workoutSecondsElapsed = 0;
  Timer? _workoutTimer;
  bool _isPaused = false;

  // Exercise Navigation
  int _currentExerciseIndex = 0;

  // Set Tracking: Map<exerciseIndex, Set<setIndex>>
  final Map<int, Set<int>> _completedSetsMap = {};

  // Rest Timer State
  bool _isResting = false;
  int _restSecondsLeft = 60;
  Timer? _restTimer;

  // Default User Weight (kg) for MET calculation
  final double _userWeightKg = 65.0;

  @override
  void initState() {
    super.initState();
    _startWorkoutTimer();
  }

  void _startWorkoutTimer() {
    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused && !_isResting && mounted) {
        setState(() {
          _workoutSecondsElapsed++;
        });
      }
    });
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  // Rest Timer methods
  void _startRestTimer({int durationSeconds = 60}) {
    _restTimer?.cancel();
    setState(() {
      _isResting = true;
      _restSecondsLeft = durationSeconds;
    });

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        if (_restSecondsLeft > 1) {
          setState(() {
            _restSecondsLeft--;
          });
        } else {
          _stopRestTimer();
        }
      }
    });
  }

  void _stopRestTimer() {
    _restTimer?.cancel();
    if (mounted) {
      setState(() {
        _isResting = false;
      });
    }
  }

  void _addRestTime(int seconds) {
    setState(() {
      _restSecondsLeft += seconds;
    });
  }

  void _toggleSetCompletion(int exerciseIdx, int setIdx) {
    setState(() {
      final setSet = _completedSetsMap.putIfAbsent(exerciseIdx, () => <int>{});
      if (setSet.contains(setIdx)) {
        setSet.remove(setIdx);
      } else {
        setSet.add(setIdx);
        // Automatically trigger Rest Timer when a set is completed
        _startRestTimer(durationSeconds: 60);
      }
    });
  }

  double _calculateTotalCaloriesBurned() {
    double totalCalories = 0.0;
    final exercises = widget.session.exercises ?? [];
    if (exercises.isEmpty) return 0.0;

    final totalMins = _workoutSecondsElapsed / 60.0;
    final minsPerExercise = totalMins / exercises.length;

    for (var exItem in exercises) {
      final met = exItem.exercise.metValue ?? 5.0;
      totalCalories += CalorieCalculator.calculateCaloriesBurned(
        metValue: met,
        weightKg: _userWeightKg,
        durationMinutes: minsPerExercise,
      );
    }
    return totalCalories;
  }

  int _getCompletedSetsCount() {
    int count = 0;
    for (final setSet in _completedSetsMap.values) {
      count += setSet.length;
    }
    return count;
  }

  int _getTotalSetsCount() {
    int count = 0;
    final exercises = widget.session.exercises ?? [];
    for (var exItem in exercises) {
      count += exItem.sets ?? 4;
    }
    return count;
  }

  void _finishWorkout() {
    _workoutTimer?.cancel();
    _restTimer?.cancel();

    final totalCalories = _calculateTotalCaloriesBurned();
    final completedSets = _getCompletedSetsCount();
    final totalSets = _getTotalSetsCount();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => WorkoutSummaryScreen(
          session: widget.session,
          totalDurationSeconds: _workoutSecondsElapsed,
          totalCaloriesBurned: totalCalories,
          completedSetsCount: completedSets,
          totalSetsCount: totalSets,
        ),
      ),
    );
  }

  String _formatTimer(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  void dispose() {
    _workoutTimer?.cancel();
    _restTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exercises = widget.session.exercises ?? [];
    final currentEx = exercises.isNotEmpty && _currentExerciseIndex < exercises.length
        ? exercises[_currentExerciseIndex]
        : null;

    final totalSets = currentEx?.sets ?? 4;
    final completedSetsForEx = _completedSetsMap[_currentExerciseIndex] ?? {};

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Top Navigation Bar & Active Workout Timer
                _buildTopAppBar(exercises.length),

                // Main Workout Content
                Expanded(
                  child: currentEx == null
                      ? const Center(child: Text('Không tìm thấy bài tập', style: TextStyle(color: Colors.white)))
                      : SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Exercise Thumbnail Card
                              _buildExerciseHeaderCard(currentEx),

                              const SizedBox(height: 20),

                              // Set Completion Tracker
                              _buildSetTrackerSection(totalSets, completedSetsForEx),
                            ],
                          ),
                        ),
                ),

                // Bottom Navigation & Finish Bar
                _buildBottomActionBar(exercises.length),
              ],
            ),
          ),

          // Rest Timer Overlay (If active)
          if (_isResting) _buildRestTimerOverlay(),
        ],
      ),
    );
  }

  Widget _buildTopAppBar(int totalExercises) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Close / Exit Workout Button
          GestureDetector(
            onTap: () => _showExitConfirmation(),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
            ),
          ),

          // Active Workout Timer Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Icon(
                  _isPaused ? Icons.pause_circle_filled_rounded : Icons.timer_outlined,
                  color: _isPaused ? const Color(0xFFF59E0B) : const Color(0xFF38BDF8),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatTimer(_workoutSecondsElapsed),
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Pause / Resume Toggle
          GestureDetector(
            onTap: _togglePause,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _isPaused
                    ? const Color(0xFF10B981).withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                color: _isPaused ? const Color(0xFF10B981) : Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseHeaderCard(dynamic currentEx) {
    final String name = currentEx.exercise.name;
    final String thumbUrl = currentEx.exercise.displayImageUrl;
    final double met = currentEx.exercise.metValue ?? 5.0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image / Video Container
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: SizedBox(
              height: 200,
              width: double.infinity,
              child: Image.network(
                thumbUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFF64748B),
                  child: const Icon(Icons.fitness_center_rounded, color: Colors.white, size: 48),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Bài tập ${_currentExerciseIndex + 1}/${widget.session.exercises?.length ?? 1}',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.local_fire_department_rounded, color: Color(0xFFF97316), size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '$met METs',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  name,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetTrackerSection(int totalSets, Set<int> completedSetsForEx) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Danh sách Hiệp (Sets)',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: totalSets,
          itemBuilder: (context, setIndex) {
            final isCompleted = completedSetsForEx.contains(setIndex);

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: isCompleted
                    ? const Color(0xFF10B981).withValues(alpha: 0.15)
                    : const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isCompleted
                      ? const Color(0xFF10B981).withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? const Color(0xFF10B981)
                          : Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${setIndex + 1}',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hiệp ${setIndex + 1}',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '10 Reps • Mục tiêu chính xác',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _toggleSetCompletion(_currentExerciseIndex, setIndex),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? const Color(0xFF10B981)
                            : Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isCompleted ? Icons.check_rounded : Icons.add_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBottomActionBar(int totalExercises) {
    final isLastExercise = _currentExerciseIndex >= totalExercises - 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentExerciseIndex > 0)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: IconButton(
                onPressed: () {
                  setState(() {
                    _currentExerciseIndex--;
                  });
                },
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              ),
            ),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                if (isLastExercise) {
                  _finishWorkout();
                } else {
                  setState(() {
                    _currentExerciseIndex++;
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isLastExercise ? const Color(0xFF10B981) : AppTheme.primary,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isLastExercise ? 'Hoàn Thành Buổi Tập 🏆' : 'Bài Tiếp Theo ➔',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 16,
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

  Widget _buildRestTimerOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      width: double.infinity,
      height: double.infinity,
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Text(
              'THỜI GIAN NGHỈ GIỮA SET 🧘',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 30),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 180,
                  height: 180,
                  child: CircularProgressIndicator(
                    value: _restSecondsLeft / 60.0,
                    strokeWidth: 10,
                    backgroundColor: Colors.white10,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
                  ),
                ),
                Text(
                  _formatTimer(_restSecondsLeft),
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () => _addRestTime(10),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white38),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    '+10 giây',
                    style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 15),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _stopRestTimer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF97316),
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    'Bỏ qua (Skip)',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          'Thoát buổi tập?',
          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Tiến trình tập luyện hiện tại chưa được hoàn tất. Bạn có chắc muốn thoát không?',
          style: GoogleFonts.plusJakartaSans(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tiếp tục tập', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Thoát', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
