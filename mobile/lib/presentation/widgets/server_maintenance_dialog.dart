import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ServerMaintenanceDialog extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onContinueOffline;

  const ServerMaintenanceDialog({
    super.key,
    required this.onRetry,
    required this.onContinueOffline,
  });

  static void show(BuildContext context, {required VoidCallback onRetry, required VoidCallback onContinueOffline}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ServerMaintenanceDialog(
        onRetry: () {
          Navigator.of(ctx).pop();
          onRetry();
        },
        onContinueOffline: () {
          Navigator.of(ctx).pop();
          onContinueOffline();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.build_circle_rounded,
                color: Color(0xFFF59E0B),
                size: 48,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Hệ Thống Đang Bảo Trì 🛠️',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Máy chủ BodyPilot đang quá tải hoặc đang trong quá trình nâng cấp hệ thống. Bạn vẫn có thể tiếp tục sử dụng ứng dụng ở Chế độ Ngoại tuyến.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onRetry,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      'Thử lại',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onContinueOffline,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF97316),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      'Dùng Offline',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
