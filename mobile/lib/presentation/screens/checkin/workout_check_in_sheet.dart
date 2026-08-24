import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/presentation/bloc/user/user_cubit.dart';
import 'package:mobile/presentation/bloc/user/user_state.dart';
import 'package:mobile/presentation/bloc/checkin/checkin_cubit.dart';
import 'package:mobile/presentation/bloc/step/step_cubit.dart';
import 'package:mobile/data/repositories/step_repository.dart';
import 'package:mobile/presentation/screens/checkin/checkin_result_dialog.dart';
import 'package:mobile/data/services/token_service.dart';
import 'package:core_shared/models/check_in_model.dart';

class WorkoutCheckInSheet extends StatefulWidget {
  const WorkoutCheckInSheet({super.key});

  @override
  State<WorkoutCheckInSheet> createState() => _WorkoutCheckInSheetState();
}

class _WorkoutCheckInSheetState extends State<WorkoutCheckInSheet> {
  bool _hasNewInjury = false;
  final Set<String> _selectedInjuredParts = {};
  String _selectedWorkoutState = 'GOOD';
  bool _isSubmitting = false;

  final List<Map<String, String>> _bodyParts = [
    {'value': 'KNEE', 'label': 'Khớp gối'},
    {'value': 'WRIST', 'label': 'Cổ tay'},
    {'value': 'LOWER_BACK', 'label': 'Thắt lưng'},
    {'value': 'SHOULDER', 'label': 'Bờ vai'},
    {'value': 'ANKLE', 'label': 'Cổ chân'},
  ];

  final List<Map<String, String>> _workoutStates = [
    {'value': 'GOOD', 'label': 'Tập luyện tốt & Phục hồi nhanh'},
    {'value': 'MODERATE', 'label': 'Tập luyện vừa sức & Hoàn thành >80%'},
    {'value': 'SORE', 'label': 'Cơ bắp nhức mỏi dai dẳng'},
    {'value': 'SKIPPED', 'label': 'Bỏ lỡ nhiều buổi do bận/bệnh'},
  ];

  Future<Map<String, dynamic>> _fetchReal7DayWorkoutStats() async {
    try {
      final userId = TokenService.getUserId();
      if (userId == null || userId.isEmpty) {
        return {'stepCount': 0, 'caloriesBurned': 0, 'activeMinutes': 0};
      }

      final now = DateTime.now();
      final startDate = now.subtract(const Duration(days: 6));
      final history = await stepRepository.getStepHistory(
        userId,
        startDate: startDate,
        endDate: now,
      );

      int total7DaySteps = 0;
      double total7DayCal = 0.0;

      for (var item in history) {
        total7DaySteps += item.stepCount;
        total7DayCal += item.caloriesBurned;
      }

      if (total7DaySteps == 0 && mounted) {
        try {
          final liveSteps = context.read<StepCubit>().state.steps;
          if (liveSteps > 0) {
            total7DaySteps = liveSteps;
            total7DayCal = liveSteps * 0.04;
          }
        } catch (_) {}
      }

      int activeMinutes = (total7DaySteps / 200).round();

      return {
        'stepCount': total7DaySteps,
        'caloriesBurned': total7DayCal.round(),
        'activeMinutes': activeMinutes,
      };
    } catch (e) {
      return {'stepCount': 0, 'caloriesBurned': 0, 'activeMinutes': 0};
    }
  }

  void _toggleInjuryPart(String code) {
    setState(() {
      if (_selectedInjuredParts.contains(code)) {
        _selectedInjuredParts.remove(code);
      } else {
        _selectedInjuredParts.add(code);
      }
    });
  }

  void _submitWorkoutCheckIn() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final userState = context.read<UserCubit>().state;
      double currentWeight = 60.0;
      if (userState is UserLoaded) {
        currentWeight = userState.user.metrics?.weight ?? 60.0;
      }

      final request = CheckInRequestModel(
        newWeight: currentWeight,
        adherenceLevel: _selectedWorkoutState == 'GOOD' ? 'EXCELLENT' : (_selectedWorkoutState == 'MODERATE' ? 'GOOD' : 'NEEDS_WORK'),
        energyLevel: _selectedWorkoutState == 'SORE' ? 'TIRED' : 'NORMAL',
        hungerLevel: 'NORMAL',
        goalChoice: 'KEEP_SAME',
        workoutState: _selectedWorkoutState,
        hasInjury: _hasNewInjury,
        injuredParts: _hasNewInjury ? _selectedInjuredParts.toList() : [],
      );

      final checkInCubit = context.read<CheckInCubit>();
      final userCubit = context.read<UserCubit>();

      final result = await checkInCubit.submitCheckIn(request);
      if (result != null) {
        final realStats = await _fetchReal7DayWorkoutStats();

        await TokenService.setWorkoutCheckInDone(true, summary: {
          'weight': result.newWeight,
          'weightChange': result.weightChange,
          'activeMinutes': realStats['activeMinutes'],
          'targetActiveMinutes': 150,
          'stepCount': realStats['stepCount'],
          'caloriesBurned': realStats['caloriesBurned'],
          'recoveryStatus': _hasNewInjury ? 'Cần chú ý chấn thương 🩹' : 'Phục hồi tốt ⚡',
          'aiFeedback': result.aiFeedback.isNotEmpty ? result.aiFeedback : result.advice,
        });

        await userCubit.fetchUserProfile();
        await checkInCubit.fetchCheckInStatus();

        if (mounted) {
          final navigator = Navigator.of(context);
          final rootContext = navigator.context;
          navigator.pop(); // Close sheet

          showDialog(
            context: rootContext,
            builder: (_) => CheckInResultDialog(result: result),
          );
        }
      } else {
        setState(() {
          _isSubmitting = false;
        });
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Có lỗi xảy ra: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFF3B82F6).withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.fitness_center_rounded, color: Color(0xFF3B82F6), size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Check-in Luyện Tập Chủ Nhật',
                        style: GoogleFonts.beVietnamPro(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                      ),
                      Text(
                        'Khảo sát chấn thương & thể lực tuần mới',
                        style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Step 1: Workout state
            Text('1. Đánh giá tuần tập vừa qua của bạn:', style: GoogleFonts.beVietnamPro(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF334155))),
            const SizedBox(height: 10),
            Column(
              children: _workoutStates.map((opt) {
                final selected = _selectedWorkoutState == opt['value'];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    tileColor: selected ? const Color(0xFF3B82F6).withOpacity(0.08) : const Color(0xFFF8FAFC),
                    title: Text(opt['label']!, style: GoogleFonts.inter(fontSize: 14, fontWeight: selected ? FontWeight.bold : FontWeight.w500)),
                    trailing: selected ? const Icon(Icons.check_circle_rounded, color: Color(0xFF3B82F6)) : null,
                    onTap: () => setState(() => _selectedWorkoutState = opt['value']!),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Step 2: Injury & Health check (Crucial requirement)
            Text('2. Khảo sát Chấn Thương & Bệnh Tật:', style: GoogleFonts.beVietnamPro(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF334155))),
            const SizedBox(height: 8),
            Text(
              'Nếu bạn gặp chấn thương mới hoặc bị đau khớp, AI sẽ tự động loại bỏ các bài tập nguy hiểm.',
              style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B), height: 1.4),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Tôi có chấn thương / vùng đau mới tuần này', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
              subtitle: Text(_hasNewInjury ? 'Hãy chọn các vùng bị ảnh hưởng bên dưới' : 'Thể trạng bình thường, không đau nhức', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
              value: _hasNewInjury,
              activeColor: AppTheme.primary,
              onChanged: (val) => setState(() => _hasNewInjury = val),
            ),

            if (_hasNewInjury) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _bodyParts.map((part) {
                  final selected = _selectedInjuredParts.contains(part['value']);
                  return FilterChip(
                    label: Text(part['label']!),
                    selected: selected,
                    onSelected: (_) => _toggleInjuryPart(part['value']!),
                    selectedColor: const Color(0xFFEF4444).withOpacity(0.15),
                    checkmarkColor: const Color(0xFFEF4444),
                    labelStyle: TextStyle(color: selected ? const Color(0xFFDC2626) : const Color(0xFF475569), fontWeight: FontWeight.bold, fontSize: 13),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitWorkoutCheckIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                    : Text('Hoàn Tất Check-in', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
