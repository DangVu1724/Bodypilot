import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AiMealBottomBar extends StatelessWidget {
  final TextEditingController feedbackController;
  final bool isRegenerating;
  final bool isSaving;
  final bool isLoading;
  final VoidCallback onSendFeedback;
  final VoidCallback onCancel;
  final VoidCallback onApply;

  const AiMealBottomBar({
    super.key,
    required this.feedbackController,
    required this.isRegenerating,
    required this.isSaving,
    required this.isLoading,
    required this.onSendFeedback,
    required this.onCancel,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.of(context).padding.bottom + 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(color: Colors.grey.shade200.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, -4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Feedback Chat Input Field
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Color(0xFFFF7A30), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: feedbackController,
                    enabled: !isRegenerating && !isSaving,
                    style: GoogleFonts.workSans(fontSize: 13.5, color: const Color(0xFF0F172A)),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onSendFeedback(),
                    decoration: const InputDecoration(
                      hintText: 'Nhập phản hồi với AI (VD: Đổi món sáng...)',
                      hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                isRegenerating
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF7A30)),
                        ),
                      )
                    : InkWell(
                        onTap: (isSaving || isLoading) ? null : onSendFeedback,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: const BoxDecoration(color: Color(0xFFFF7A30), shape: BoxShape.circle),
                          child: const Icon(Icons.send_rounded, color: Colors.white, size: 15),
                        ),
                      ),
              ],
            ),
          ),

          // Action Buttons (Hủy & Áp dụng thực đơn)
          Row(
            children: [
              Expanded(
                flex: 2,
                child: OutlinedButton(
                  onPressed: (isSaving || isRegenerating) ? null : onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF64748B),
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Hủy'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: ElevatedButton(
                  onPressed: (isSaving || isRegenerating) ? null : onApply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7A30),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Áp dụng thực đơn'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
