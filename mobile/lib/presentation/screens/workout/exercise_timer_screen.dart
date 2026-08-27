import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:core_shared/models/exercise_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/presentation/bloc/workout/workout_diary_cubit.dart';
import '../../../../core/theme/app_theme.dart';

class ExerciseTimerScreen extends StatefulWidget {
  final ExerciseModel exercise;
  final String? dailyWorkoutItemId;
  final DateTime? selectedDate;
  final int? sets;
  final int? reps;
  final int? restSeconds;

  const ExerciseTimerScreen({
    super.key,
    required this.exercise,
    this.dailyWorkoutItemId,
    this.selectedDate,
    this.sets,
    this.reps,
    this.restSeconds,
  });

  @override
  State<ExerciseTimerScreen> createState() => _ExerciseTimerScreenState();
}

class _ExerciseTimerScreenState extends State<ExerciseTimerScreen> {
  late int _totalSets;
  late int _reps;
  late int _restDurationSeconds;
  late int _workDurationPerSet;

  int _currentSetIndex = 0;
  bool _isRestPhase = false;
  late int _timeLeft;
  late int _currentPhaseTotalSeconds;

  Timer? _timer;
  bool _isPaused = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _hasStartedMusic = false;

  @override
  void initState() {
    super.initState();
    _totalSets = widget.sets ?? 3;
    _reps = widget.reps ?? 20;
    _restDurationSeconds = widget.restSeconds ?? 60;

    int totalExerciseSeconds = _calculateTotalSeconds();
    _workDurationPerSet = (_totalSets > 0) ? (totalExerciseSeconds / _totalSets).round().clamp(10, 3600) : 60;

    _timeLeft = _workDurationPerSet;
    _currentPhaseTotalSeconds = _workDurationPerSet;

    _audioPlayer.setReleaseMode(ReleaseMode.loop);
    _audioPlayer.setVolume(1.0);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _resumeWorkout();
      }
    });

    _startTimer();
  }

  void _resumeWorkout() async {
    setState(() {
      _isPaused = false;
    });
    try {
      if (!_hasStartedMusic) {
        _hasStartedMusic = true;
        await _audioPlayer.play(UrlSource('https://cdn.pixabay.com/download/audio/2022/05/27/audio_1808fbf07a.mp3'));
      } else {
        await _audioPlayer.resume();
      }
    } catch (e) {
      debugPrint("[ExerciseTimerScreen Audio Error]: $e");
    }
  }

  void _pauseWorkout() async {
    setState(() {
      _isPaused = true;
    });
    try {
      await _audioPlayer.pause();
    } catch (e) {
      debugPrint("[ExerciseTimerScreen Pause Error]: $e");
    }
  }

  void _togglePause() {
    if (_isPaused) {
      _resumeWorkout();
    } else {
      _pauseWorkout();
    }
  }

  int _calculateTotalSeconds() {
    final duration = widget.exercise.defaultDuration ?? 10;
    final unit = widget.exercise.durationUnit?.toLowerCase() ?? 'min';

    if (unit == 'sec' || unit == 'seconds') {
      return duration;
    } else if (unit == 'hour' || unit == 'hours') {
      return duration * 3600;
    }
    return duration * 60; // default to minutes
  }

  String _formatTimer(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused && mounted) {
        setState(() {
          if (_timeLeft > 1) {
            _timeLeft--;
          } else {
            _handlePhaseCompletion();
          }
        });
      }
    });
  }

  void _handlePhaseCompletion() {
    if (!_isRestPhase) {
      // End of Work Set
      if (_currentSetIndex < _totalSets - 1) {
        // Transition to Rest Phase
        _isRestPhase = true;
        _timeLeft = _restDurationSeconds;
        _currentPhaseTotalSeconds = _restDurationSeconds;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hoàn thành Hiệp ${_currentSetIndex + 1}! Bắt đầu nghỉ (${_restDurationSeconds}s)'),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        // Completed all sets
        _finishWorkout();
      }
    } else {
      // End of Rest Phase -> Advance to Next Work Set
      _isRestPhase = false;
      _currentSetIndex++;
      _timeLeft = _workDurationPerSet;
      _currentPhaseTotalSeconds = _workDurationPerSet;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bắt đầu Hiệp ${_currentSetIndex + 1} / $_totalSets!'),
          backgroundColor: AppTheme.primary,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _skipRestOrNextSet() {
    setState(() {
      if (_isRestPhase) {
        // Skip Rest -> Advance to Next Work Set
        _isRestPhase = false;
        _currentSetIndex++;
        _timeLeft = _workDurationPerSet;
        _currentPhaseTotalSeconds = _workDurationPerSet;
      } else {
        // Complete Work Set early -> Go to Rest or Finish
        _handlePhaseCompletion();
      }
    });
  }

  void _addRestTime(int extraSeconds) {
    if (_isRestPhase) {
      setState(() {
        _timeLeft += extraSeconds;
        _currentPhaseTotalSeconds += extraSeconds;
      });
    }
  }

  void _finishWorkout() {
    _timer?.cancel();
    _audioPlayer.stop();
    if (widget.dailyWorkoutItemId != null && widget.selectedDate != null) {
      context.read<WorkoutDiaryCubit>().toggleExerciseStatus(
            widget.dailyWorkoutItemId!,
            true,
            widget.selectedDate!,
          );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hoàn thành xuất sắc ${widget.exercise.name}! 🎉'),
          backgroundColor: Colors.green,
        ),
      );
    }
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              _isRestPhase ? Colors.blue.shade900.withOpacity(0.5) : Colors.black.withOpacity(0.45),
              BlendMode.darken,
            ),
            child: Image.network(
              widget.exercise.thumbnailUrl ?? 'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=800&q=80',
              fit: BoxFit.cover,
            ),
          ),
          // Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: _isRestPhase
                    ? [Colors.blue.shade900.withOpacity(0.5), Colors.transparent, Colors.black.withOpacity(0.95)]
                    : [Colors.black.withOpacity(0.4), Colors.transparent, Colors.black.withOpacity(0.95)],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),
          // Back Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
            child: Column(
              children: [
                const Spacer(),

                // Work & Rest Phase Badges
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: _isRestPhase ? Colors.grey.withOpacity(0.4) : Colors.orange.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.fitness_center, color: Colors.white, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            'Tập Hiệp ${_currentSetIndex + 1} / $_totalSets ($_reps Reps)',
                            style: AppTheme.semiboldStyle.copyWith(color: Colors.white, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: _isRestPhase ? Colors.blue.shade600 : Colors.blue.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.timer_outlined, color: Colors.white, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            'Nghỉ: ${_restDurationSeconds}s',
                            style: AppTheme.semiboldStyle.copyWith(color: Colors.white, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Exercise Name
                Text(
                  widget.exercise.name,
                  textAlign: TextAlign.center,
                  style: AppTheme.headlineStyle.copyWith(color: Colors.white, fontSize: 28, letterSpacing: -0.5),
                ),
                const SizedBox(height: 28),

                // Segmented Timeline Bar with alternating Work and Rest segments
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _isRestPhase
                              ? 'Nghỉ giữa hiệp (${_formatTimer(_timeLeft)})'
                              : 'Hiệp ${_currentSetIndex + 1} / $_totalSets (${_reps} Reps)',
                          style: AppTheme.semiboldStyle.copyWith(
                            color: _isRestPhase ? Colors.blueAccent : AppTheme.primary,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          _formatTimer(_timeLeft),
                          style: AppTheme.bodyStyle.copyWith(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Alternating Work & Rest Timeline
                    Builder(
                      builder: (context) {
                        final totalSegments = 2 * _totalSets - 1;
                        final activeSegmentIndex = _isRestPhase ? (2 * _currentSetIndex + 1) : (2 * _currentSetIndex);

                        return Row(
                          children: List.generate(totalSegments, (idx) {
                            final bool isRestSegment = (idx % 2 != 0);
                            final bool isCompleted = idx < activeSegmentIndex;
                            final bool isCurrent = idx == activeSegmentIndex;

                            double segmentValue = 0.0;
                            if (isCompleted) {
                              segmentValue = 1.0;
                            } else if (isCurrent) {
                              segmentValue = _currentPhaseTotalSeconds > 0
                                  ? (1.0 - (_timeLeft / _currentPhaseTotalSeconds)).clamp(0.0, 1.0)
                                  : 0.0;
                            } else {
                              segmentValue = 0.0;
                            }

                            final flexWidth = isRestSegment ? 1 : 3;

                            return Expanded(
                              flex: flexWidth,
                              child: Container(
                                margin: EdgeInsets.only(right: idx == totalSegments - 1 ? 0 : 4),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: segmentValue,
                                    backgroundColor: isRestSegment ? Colors.blue.withOpacity(0.12) : Colors.white12,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      isRestSegment
                                          ? (isCurrent
                                              ? Colors.blueAccent
                                              : (isCompleted ? Colors.blue.shade400.withOpacity(0.7) : Colors.white24))
                                          : (isCurrent
                                              ? AppTheme.primary
                                              : (isCompleted ? AppTheme.primary.withOpacity(0.75) : Colors.white24)),
                                    ),
                                    minHeight: isRestSegment ? 6 : 9,
                                  ),
                                ),
                              ),
                            );
                          }),
                        );
                      },
                    ),

                    const SizedBox(height: 6),

                    // Legend hint below progress bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle)),
                            const SizedBox(width: 4),
                            Text('Tập', style: AppTheme.bodyStyle.copyWith(color: Colors.white54, fontSize: 10)),
                            const SizedBox(width: 12),
                            Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle)),
                            const SizedBox(width: 4),
                            Text('Nghỉ giữa hiệp', style: AppTheme.bodyStyle.copyWith(color: Colors.white54, fontSize: 10)),
                          ],
                        ),
                        Text('Tổng ${_totalSets} hiệp', style: AppTheme.bodyStyle.copyWith(color: Colors.white54, fontSize: 10)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Bottom Control Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10)),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          // Circular Timer Indicator
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 64,
                                height: 64,
                                child: CircularProgressIndicator(
                                  value: _currentPhaseTotalSeconds > 0 ? _timeLeft / _currentPhaseTotalSeconds : 0,
                                  strokeWidth: 4,
                                  backgroundColor: Colors.white.withOpacity(0.1),
                                  valueColor: AlwaysStoppedAnimation<Color>(_isRestPhase ? Colors.blueAccent : AppTheme.primary),
                                ),
                              ),
                              Text(
                                _formatTimer(_timeLeft),
                                style: AppTheme.headlineStyle.copyWith(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          // Status Label
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _isRestPhase
                                      ? 'Nghỉ giữa hiệp'
                                      : (_isPaused ? 'Đã tạm dừng' : 'Đang tập Hiệp ${_currentSetIndex + 1}'),
                                  style: AppTheme.semiboldStyle.copyWith(
                                    color: _isRestPhase ? Colors.blueAccent : Colors.white,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(_isRestPhase ? Icons.timer : Icons.flash_on,
                                        color: _isRestPhase ? Colors.blueAccent : AppTheme.primary, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      _isRestPhase
                                          ? 'Chuẩn bị Hiệp ${_currentSetIndex + 2}'
                                          : 'Cố gắng hoàn thành',
                                      style: AppTheme.bodyStyle.copyWith(
                                        color: Colors.white.withOpacity(0.6),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Pause / Play Button
                          GestureDetector(
                            onTap: _togglePause,
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Icon(
                                _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                        ],
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
