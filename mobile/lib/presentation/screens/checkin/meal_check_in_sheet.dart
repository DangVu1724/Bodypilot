import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/presentation/bloc/user/user_cubit.dart';
import 'package:mobile/presentation/screens/meal/ai_meal_suggestion_screen.dart';

class MealCheckInSheet extends StatefulWidget {
  final double currentWeight;
  final String currentGoal;

  const MealCheckInSheet({
    super.key,
    required this.currentWeight,
    required this.currentGoal,
  });

  @override
  State<MealCheckInSheet> createState() => _MealCheckInSheetState();
}

class _MealCheckInSheetState extends State<MealCheckInSheet> {
  late TextEditingController _weightController;
  bool? _isGoalCompleted;
  String _selectedNewGoal = 'MAINTAIN';
  String _selectedEnergyStatus = 'NORMAL';
  bool _isSubmitting = false;

  final List<Map<String, String>> _newGoalOptions = [
    {'value': 'MAINTAIN', 'label': 'Duy trì vóc dáng hiện tại ⚖️'},
    {'value': 'BUILD_MUSCLE', 'label': 'Tăng cơ & Cải thiện thể hình 💪'},
    {'value': 'LOSE_0_5KG', 'label': 'Giảm cân nhẹ nhàng (-0.5kg/tuần) 🥗'},
    {'value': 'LOSE_1KG', 'label': 'Giảm cân nhanh (-1kg/tuần) 🔥'},
  ];

  final List<Map<String, String>> _energyOptions = [
    {'value': 'ENERGETIC', 'label': 'Sung sức & Khỏe khoắn ⚡'},
    {'value': 'NORMAL', 'label': 'Bình thường & Thích nghi tốt 😃'},
    {'value': 'TIRED', 'label': 'Đuối sức / Mệt mỏi 😫'},
    {'value': 'HUNGRY', 'label': 'Thèm ăn quá mức 🍔'},
  ];

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(text: widget.currentWeight.toString());
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  void _submitMealCheckIn() async {
    final weight = double.tryParse(_weightController.text);
    if (weight == null || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập cân nặng hợp lệ!'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      Navigator.pop(context);
      context.read<UserCubit>().fetchUserProfile();

      if (mounted) {
        if (_isGoalCompleted == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Chúc mừng bạn đã hoàn thành mục tiêu! Hãy tạo thực đơn cho mục tiêu mới.'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã ghi nhận Check-in Chủ Nhật! AI đang sinh thực đơn điều chỉnh...'),
              backgroundColor: Colors.green,
            ),
          );
        }

        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
            builder: (context) => const AiMealSuggestionScreen(days: 7),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Có lỗi xảy ra: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
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
                decoration: BoxDecoration(color: const Color(0xFFFF7A30).withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.restaurant_menu_rounded, color: Color(0xFFFF7A30), size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Check-in Dinh Dưỡng Chủ Nhật',
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                    ),
                    Text(
                      'Tổng kết & Điều chỉnh calo tuần mới',
                      style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Step 1: Weight input
          Text('1. Cân nặng hiện tại của bạn:', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF334155))),
          const SizedBox(height: 8),
          TextField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              suffixText: 'kg',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            ),
          ),
          const SizedBox(height: 20),

          // Step 2: Goal Completion check
          Text('2. Bạn đã hoàn thành mục tiêu cân nặng chưa?', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF334155))),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _isGoalCompleted = false),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _isGoalCompleted == false ? AppTheme.primary.withOpacity(0.12) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _isGoalCompleted == false ? AppTheme.primary : const Color(0xFFE2E8F0), width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        'Chưa hoàn thành',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: _isGoalCompleted == false ? AppTheme.primary : const Color(0xFF475569)),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _isGoalCompleted = true),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _isGoalCompleted == true ? Colors.green.withOpacity(0.12) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _isGoalCompleted == true ? Colors.green : const Color(0xFFE2E8F0), width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        'Đã hoàn thành 🎉',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: _isGoalCompleted == true ? Colors.green.shade700 : const Color(0xFF475569)),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Conditional step 3
          if (_isGoalCompleted == true) ...[
            Text('3. Chọn mục tiêu mới của bạn:', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF334155))),
            const SizedBox(height: 10),
            Column(
              children: _newGoalOptions.map((opt) {
                final selected = _selectedNewGoal == opt['value'];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    tileColor: selected ? AppTheme.primary.withOpacity(0.08) : const Color(0xFFF8FAFC),
                    title: Text(opt['label']!, style: GoogleFonts.inter(fontSize: 14, fontWeight: selected ? FontWeight.bold : FontWeight.w500)),
                    trailing: selected ? const Icon(Icons.check_circle_rounded, color: AppTheme.primary) : null,
                    onTap: () => setState(() => _selectedNewGoal = opt['value']!),
                  ),
                );
              }).toList(),
            ),
          ] else if (_isGoalCompleted == false) ...[
            Text('3. Thể trạng tuần qua của bạn:', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF334155))),
            const SizedBox(height: 10),
            Column(
              children: _energyOptions.map((opt) {
                final selected = _selectedEnergyStatus == opt['value'];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    tileColor: selected ? AppTheme.primary.withOpacity(0.08) : const Color(0xFFF8FAFC),
                    title: Text(opt['label']!, style: GoogleFonts.inter(fontSize: 14, fontWeight: selected ? FontWeight.bold : FontWeight.w500)),
                    trailing: selected ? const Icon(Icons.check_circle_rounded, color: AppTheme.primary) : null,
                    onTap: () => setState(() => _selectedEnergyStatus = opt['value']!),
                  ),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: (_isGoalCompleted == null || _isSubmitting) ? null : _submitMealCheckIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                  : Text('Xác Nhận & Sinh Thực Đơn AI Tuần Mới', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}
