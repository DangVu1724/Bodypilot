class CalorieCalculator {
  /// Calculate calories burned using standard ACSM formula:
  /// Calories = (MET * 3.5 * weightKg / 200) * durationMinutes
  static double calculateCaloriesBurned({
    required double metValue,
    required double weightKg,
    required double durationMinutes,
  }) {
    final effectiveMet = metValue > 0 ? metValue : 5.0; // Fallback to 5.0 METs
    final effectiveWeight = weightKg > 0 ? weightKg : 65.0; // Fallback to 65kg
    final effectiveDuration = durationMinutes > 0 ? durationMinutes : 0.0;

    return ((effectiveMet * 3.5 * effectiveWeight) / 200.0) * effectiveDuration;
  }
}
