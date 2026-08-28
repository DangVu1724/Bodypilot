import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/theme/app_theme.dart';

/// Modal bottom sheet chọn nhóm cơ tập trung khi tạo lịch tập AI
class WorkoutAiFocusSheet extends StatefulWidget {
  final String initialFocus;
  final ValueChanged<String> onSelectFocus;

  const WorkoutAiFocusSheet({
    super.key,
    required this.initialFocus,
    required this.onSelectFocus,
  });

  static const List<Map<String, String>> focusOptions = [
    {'label': 'Không có (Tự động)', 'value': 'NONE'},
    {'label': 'Ngực', 'value': 'CHEST'},
    {'label': 'Lưng', 'value': 'BACK'},
    {'label': 'Chân', 'value': 'LEGS'},
    {'label': 'Vai', 'value': 'SHOULDERS'},
    {'label': 'Tay', 'value': 'ARMS'},
    {'label': 'Bụng / Cơ lõi (Core)', 'value': 'CORE'},
    {'label': 'Toàn thân', 'value': 'FULL_BODY'},
  ];

  @override
  State<WorkoutAiFocusSheet> createState() => _WorkoutAiFocusSheetState();
}

class _WorkoutAiFocusSheetState extends State<WorkoutAiFocusSheet> {
  late String _selectedFocus;

  @override
  void initState() {
    super.initState();
    _selectedFocus = widget.initialFocus;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Chọn nhóm cơ ưu tiên tập',
            style: GoogleFonts.workSans(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
          ),
          const SizedBox(height: 6),
          Text(
            'AI sẽ ưu tiên thiết lập thêm các bài tập thuộc nhóm cơ này vào lịch của bạn.',
            style: AppTheme.bodyStyle.copyWith(color: const Color(0xFF64748B), fontSize: 13),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: WorkoutAiFocusSheet.focusOptions.map((opt) {
              final isSelected = opt['value'] == _selectedFocus;
              return ChoiceChip(
                label: Text(opt['label']!),
                selected: isSelected,
                selectedColor: AppTheme.primary,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF475569),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
                backgroundColor: const Color(0xFFF1F5F9),
                onSelected: (val) {
                  if (val) {
                    setState(() {
                      _selectedFocus = opt['value']!;
                    });
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                widget.onSelectFocus(_selectedFocus);
                Navigator.pop(context);
              },
              child: Text(
                'Áp dụng và Tạo Lịch Tập AI',
                style: GoogleFonts.workSans(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
