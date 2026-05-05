import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/exercise_model.dart';

class ExerciseTimerScreen extends StatefulWidget {
  final ExerciseModel exercise;

  const ExerciseTimerScreen({super.key, required this.exercise});

  @override
  State<ExerciseTimerScreen> createState() => _ExerciseTimerScreenState();
}

class _ExerciseTimerScreenState extends State<ExerciseTimerScreen> {
  late int _timeLeft;
  late int _totalDuration;
  Timer? _timer;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _totalDuration = _calculateTotalSeconds();
    _timeLeft = _totalDuration;
    _startTimer();
  }

  int _calculateTotalSeconds() {
    final duration = widget.exercise.defaultDuration ?? 60;
    final unit = widget.exercise.durationUnit?.toLowerCase() ?? 'sec';

    if (unit == 'min' || unit == 'minutes') {
      return duration * 60;
    } else if (unit == 'hour' || unit == 'hours') {
      return duration * 3600;
    }
    return duration; // default to seconds
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused && mounted) {
        setState(() {
          if (_timeLeft > 0) {
            _timeLeft--;
          } else {
            _timer?.cancel();
            // Handle completion if needed
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
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
              Colors.black.withOpacity(0.4),
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
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.transparent,
                  Colors.black.withOpacity(0.9),
                ],
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              children: [
                const Spacer(),
                // Exercise Label
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Text(
                    'Exercise Detail',
                    style: AppTheme.semiboldStyle.copyWith(color: Colors.white70, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 16),
                // Exercise Name
                Text(
                  widget.exercise.name,
                  textAlign: TextAlign.center,
                  style: AppTheme.headlineStyle.copyWith(color: Colors.white, fontSize: 32, letterSpacing: -0.5),
                ),
                const SizedBox(height: 40),
                // Progress Bar
                Row(
                  children: [
                    Text('0', style: AppTheme.bodyStyle.copyWith(color: Colors.white54, fontSize: 10)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: 1 - (_timeLeft / _totalDuration),
                          backgroundColor: Colors.white10,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('$_totalDuration', style: AppTheme.bodyStyle.copyWith(color: Colors.white54, fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 48),
                // Bottom Action Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Countdown Circle
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 56,
                            height: 56,
                            child: CircularProgressIndicator(
                              value: _timeLeft / _totalDuration,
                              strokeWidth: 4,
                              backgroundColor: Colors.white.withOpacity(0.05),
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          Text(
                            '$_timeLeft',
                            style: AppTheme.headlineStyle.copyWith(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(width: 20),
                      // Next Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Target Reached',
                              style: AppTheme.semiboldStyle.copyWith(color: Colors.white, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.flash_on, color: Colors.white.withOpacity(0.5), size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  'Keep it up!',
                                  style: AppTheme.bodyStyle.copyWith(color: Colors.white.withOpacity(0.5), fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Pause Button
                      GestureDetector(
                        onTap: () => setState(() => _isPaused = !_isPaused),
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B00), // Premium Orange
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
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
