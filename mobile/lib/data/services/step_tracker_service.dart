import 'dart:async';
import 'package:intl/intl.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StepTrackerService {
  static const String _baselineStepsKey = 'step_baseline_steps';
  static const String _baselineDateKey = 'step_baseline_date';
  static const String _todayStepsKey = 'step_today_steps';
  static const String _lastRawStepsKey = 'step_last_raw_steps';

  StreamSubscription<StepCount>? _stepSubscription;
  StreamSubscription<PedestrianStatus>? _statusSubscription;

  Future<bool> requestPermission() async {
    final status = await Permission.activityRecognition.request();
    return status.isGranted;
  }

  Future<void> initStepTracker({
    required Function(int todaySteps) onStepCountUpdated,
    Function(String status)? onStatusChanged,
    Function(dynamic error)? onError,
  }) async {
    final bool granted = await requestPermission();
    if (!granted) {
      onError?.call('Chưa cấp quyền đếm bước chân.');
      return;
    }

    try {
      _stepSubscription?.cancel();
      _stepSubscription = Pedometer.stepCountStream.listen(
        (StepCount event) async {
          final int todaySteps = await _calculateTodaySteps(event.steps);
          onStepCountUpdated(todaySteps);
        },
        onError: (error) {
          onError?.call(error);
        },
      );

      if (onStatusChanged != null) {
        _statusSubscription?.cancel();
        _statusSubscription = Pedometer.pedestrianStatusStream.listen(
          (PedestrianStatus event) {
            onStatusChanged(event.status);
          },
          onError: (error) {
            onError?.call(error);
          },
        );
      }
    } catch (e) {
      onError?.call(e);
    }
  }

  Future<int> _calculateTodaySteps(int rawHardwareSteps) async {
    final prefs = await SharedPreferences.getInstance();
    final String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final String? savedDate = prefs.getString(_baselineDateKey);
    int baseline = prefs.getInt(_baselineStepsKey) ?? -1;
    int lastRaw = prefs.getInt(_lastRawStepsKey) ?? -1;
    int savedTodaySteps = prefs.getInt(_todayStepsKey) ?? 0;

    // Case 1: First time app initialization
    if (baseline < 0 || lastRaw < 0) {
      final int initialToday = (savedDate == todayStr && savedTodaySteps > 0) ? savedTodaySteps : 0;
      baseline = (rawHardwareSteps >= initialToday) ? (rawHardwareSteps - initialToday) : rawHardwareSteps;
      await prefs.setString(_baselineDateKey, todayStr);
      await prefs.setInt(_baselineStepsKey, baseline);
      await prefs.setInt(_lastRawStepsKey, rawHardwareSteps);
      await prefs.setInt(_todayStepsKey, initialToday);
      return initialToday;
    }

    // Case 2: Device reboot detected (raw hardware counter reset to smaller number)
    if (rawHardwareSteps < baseline || rawHardwareSteps < lastRaw) {
      if (savedDate == todayStr) {
        baseline = (rawHardwareSteps - savedTodaySteps).clamp(0, rawHardwareSteps);
      } else {
        baseline = rawHardwareSteps;
        await prefs.setString(_baselineDateKey, todayStr);
      }
      await prefs.setInt(_baselineStepsKey, baseline);
    }
    // Case 3: New day (Date changed)
    else if (savedDate != todayStr) {
      if (lastRaw >= 0 && rawHardwareSteps >= lastRaw) {
        baseline = lastRaw;
      } else {
        baseline = rawHardwareSteps;
      }
      await prefs.setString(_baselineDateKey, todayStr);
      await prefs.setInt(_baselineStepsKey, baseline);
    }

    // Always update last known raw steps
    await prefs.setInt(_lastRawStepsKey, rawHardwareSteps);

    final int todaySteps = (rawHardwareSteps - baseline).clamp(0, 1000000);
    await prefs.setInt(_todayStepsKey, todaySteps);
    return todaySteps;
  }

  Future<void> restoreTodaySteps(int backendSteps) async {
    if (backendSteps <= 0) return;
    final prefs = await SharedPreferences.getInstance();
    final String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final String? savedDate = prefs.getString(_baselineDateKey);
    final int currentSaved = (savedDate == todayStr) ? (prefs.getInt(_todayStepsKey) ?? 0) : 0;

    if (currentSaved >= backendSteps) {
      return;
    }

    final int lastRaw = prefs.getInt(_lastRawStepsKey) ?? -1;
    await prefs.setString(_baselineDateKey, todayStr);
    await prefs.setInt(_todayStepsKey, backendSteps);

    if (lastRaw >= backendSteps) {
      final int newBaseline = lastRaw - backendSteps;
      await prefs.setInt(_baselineStepsKey, newBaseline);
    }
  }

  Future<int> getSavedTodaySteps() async {
    final prefs = await SharedPreferences.getInstance();
    final String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final String? savedDate = prefs.getString(_baselineDateKey);
    if (savedDate == todayStr) {
      return prefs.getInt(_todayStepsKey) ?? 0;
    }
    return 0;
  }

  void dispose() {
    _stepSubscription?.cancel();
    _statusSubscription?.cancel();
  }
}
