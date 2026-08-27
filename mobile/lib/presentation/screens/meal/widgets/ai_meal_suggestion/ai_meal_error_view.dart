import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/theme/app_theme.dart';

class AiMealErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onBack;

  const AiMealErrorView({
    super.key,
    required this.onRetry,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: const Icon(Icons.cloud_off_rounded, size: 56, color: Colors.red),
            ),
            const SizedBox(height: 24),
            Text(
              'Không thể khởi tạo thực đơn AI',
              style: GoogleFonts.workSans(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Đã xảy ra sự cố trong quá trình tạo gợi ý thực đơn từ AI. Vui lòng thử lại sau.',
              style: AppTheme.bodyStyle.copyWith(color: const Color(0xFF64748B), fontSize: 14, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text(
                  'Thử lại ngay',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7A30),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onBack,
              child: Text('Quay lại', style: AppTheme.semiboldStyle.copyWith(color: AppTheme.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }
}
