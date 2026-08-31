import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core_shared/models/check_in_model.dart';
import 'package:mobile/presentation/bloc/checkin/checkin_cubit.dart';
import 'package:mobile/presentation/bloc/checkin/checkin_state.dart';
import 'package:mobile/presentation/bloc/user/user_cubit.dart';
import 'checkin_result_dialog.dart';

class CheckInBottomSheet extends StatefulWidget {
  final CheckInStatusModel status;

  const CheckInBottomSheet({super.key, required this.status});

  @override
  State<CheckInBottomSheet> createState() => _CheckInBottomSheetState();
}

class _CheckInBottomSheetState extends State<CheckInBottomSheet> {
  late double _weight;
  String _adherence = 'GOOD';
  String _energy = 'NORMAL';
  String _hunger = 'NORMAL';
  String _goalChoice = 'KEEP_SAME';

  @override
  void initState() {
    super.initState();
    _weight = widget.status.currentWeight;
  }

  @override
  Widget build(BuildContext context) {
    final prevWeight = widget.status.currentWeight;
    final minAllowedWeight = (prevWeight - 10.0).clamp(30.0, 250.0);
    final maxAllowedWeight = (prevWeight + 10.0).clamp(30.0, 250.0);
    final diff = _weight - prevWeight;
    final canDecrease = _weight > minAllowedWeight;
    final canIncrease = _weight < maxAllowedWeight;

    return BlocListener<CheckInCubit, CheckInState>(
      listener: (context, state) {
        if (state is CheckInSuccess) {
          Navigator.pop(context); // Close bottom sheet
          context.read<UserCubit>().fetchUserProfile(); // Refresh user profile cache
          showDialog(
            context: context,
            builder: (_) => CheckInResultDialog(result: state.result),
          );
        } else if (state is CheckInError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: ${state.message}'), backgroundColor: Colors.redAccent),
          );
        }
      },
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          top: 24,
          left: 24,
          right: 24,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A), // Slate 900
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Khảo Sát Tiến Độ AI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Sau khoảng thời gian thực hiện kế hoạch, hãy cập nhật để AI đánh giá và tinh chỉnh chỉ số TDEE cho bạn.',
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 24),

              // 1. Weight adjustment
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '1. Cân nặng hiện tại của bạn (kg)',
                    style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    'Giới hạn: ±10kg',
                    style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: canDecrease
                          ? () {
                              setState(() {
                                final next = (_weight - 0.5).clamp(minAllowedWeight, maxAllowedWeight);
                                _weight = double.parse(next.toStringAsFixed(1));
                              });
                            }
                          : null,
                      icon: Icon(
                        Icons.remove_circle_outline,
                        color: canDecrease ? Colors.white : Colors.white24,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Column(
                      children: [
                        Text(
                          '${_weight.toStringAsFixed(1)} kg',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (diff != 0)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            decoration: BoxDecoration(
                              color: (diff < 0 ? Colors.green : Colors.amber).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${diff > 0 ? "+" : ""}${diff.toStringAsFixed(1)} kg',
                              style: TextStyle(
                                color: diff < 0 ? Colors.greenAccent : Colors.amberAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    IconButton(
                      onPressed: canIncrease
                          ? () {
                              setState(() {
                                final next = (_weight + 0.5).clamp(minAllowedWeight, maxAllowedWeight);
                                _weight = double.parse(next.toStringAsFixed(1));
                              });
                            }
                          : null,
                      icon: Icon(
                        Icons.add_circle_outline,
                        color: canIncrease ? Colors.white : Colors.white24,
                        size: 32,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 2. Adherence level
              const Text(
                '2. Mức độ tuân thủ thực đơn / tập luyện vừa qua',
                style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  _buildSelectChip('Rất tốt (>90%)', 'EXCELLENT', _adherence, (val) => setState(() => _adherence = val)),
                  _buildSelectChip('Khá tốt (~70%)', 'GOOD', _adherence, (val) => setState(() => _adherence = val)),
                  _buildSelectChip('Gặp khó khăn (<50%)', 'NEEDS_WORK', _adherence, (val) => setState(() => _adherence = val)),
                ],
              ),
              const SizedBox(height: 20),

              // 3. Goal action
              const Text(
                '3. Định hướng mục tiêu tiếp theo',
                style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildSelectChip('Giữ nguyên mục tiêu', 'KEEP_SAME', _goalChoice, (val) => setState(() => _goalChoice = val)),
                  _buildSelectChip('Giảm 0.5kg/tuần', 'LOSE_0_5KG', _goalChoice, (val) => setState(() => _goalChoice = val)),
                  _buildSelectChip('Giảm 1kg/tuần', 'LOSE_1KG', _goalChoice, (val) => setState(() => _goalChoice = val)),
                  _buildSelectChip('Duy trì cân nặng', 'MAINTAIN', _goalChoice, (val) => setState(() => _goalChoice = val)),
                  _buildSelectChip('Tăng cơ', 'GAIN_MUSCLE', _goalChoice, (val) => setState(() => _goalChoice = val)),
                ],
              ),
              const SizedBox(height: 28),

              // Submit Button
              BlocBuilder<CheckInCubit, CheckInState>(
                builder: (context, state) {
                  final isSubmitting = state is CheckInSubmitting;
                  return SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () {
                              final req = CheckInRequestModel(
                                newWeight: _weight,
                                adherenceLevel: _adherence,
                                energyLevel: _energy,
                                hungerLevel: _hunger,
                                goalChoice: _goalChoice,
                              );
                              context.read<CheckInCubit>().submitCheckIn(req);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF38BDF8),
                        foregroundColor: const Color(0xFF0F172A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Color(0xFF0F172A), strokeWidth: 2.5),
                            )
                          : const Text(
                              'Hoàn Tất Khảo Sát & Đánh Giá AI',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectChip(String label, String value, String currentGroupValue, Function(String) onSelect) {
    final isSelected = currentGroupValue == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelect(value),
      selectedColor: const Color(0xFF38BDF8),
      backgroundColor: Colors.white.withOpacity(0.08),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF0F172A) : Colors.white,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: BorderSide(color: isSelected ? const Color(0xFF38BDF8) : Colors.transparent),
    );
  }
}
