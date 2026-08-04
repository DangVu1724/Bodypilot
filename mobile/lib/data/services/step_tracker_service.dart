import 'dart:async';
import 'package:intl/intl.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StepTrackerService {
  static const String _baselineStepsKey = 'step_baseline_steps';
  static const String _baselineDateKey = 'step_baseline_date';
  static const String _todayStepsKey = 'step_today_steps';

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

    // Reset baseline if new day or new installation
    if (savedDate != todayStr || baseline < 0 || rawHardwareSteps < baseline) {
      baseline = rawHardwareSteps;
      await prefs.setString(_baselineDateKey, todayStr);
      await prefs.setInt(_baselineStepsKey, baseline);
    }

    final int todaySteps = (rawHardwareSteps - baseline).clamp(0, 1000000);
    await prefs.setInt(_todayStepsKey, todaySteps);
    return todaySteps;
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
