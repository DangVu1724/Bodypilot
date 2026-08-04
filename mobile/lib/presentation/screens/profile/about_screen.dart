import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Về BodyPilot',
          style: GoogleFonts.workSans(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Logo & App Name Header
            Center(
              child: Column(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF07025), Color(0xFFFF9E66)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF07025).withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.fitness_center_rounded, color: Colors.white, size: 48),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'BodyPilot AI',
                    style: GoogleFonts.workSans(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      'Phiên bản 1.0.0 (Pro AI Edition)',
                      style: GoogleFonts.workSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Description Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Text(
                'BodyPilot là trợ lý cá nhân thông minh ứng dụng trí tuệ nhân tạo (AI) đột phá, giúp bạn thiết lập thực đơn chuẩn dinh dưỡng và lịch tập luyện thể thao cá nhân hóa hoàn toàn phù hợp với thể trạng, mục tiêu cân nặng và hạn chế chấn thương của bạn.',
                style: GoogleFonts.workSans(
                  fontSize: 14,
                  height: 1.6,
                  color: const Color(0xFF475569),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),

            // Core Features Section
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Tính Năng Nổi Bật',
                style: GoogleFonts.workSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildFeatureTile(
              icon: Icons.auto_awesome_rounded,
              color: const Color(0xFF8B5CF6),
              title: 'Lập Thực Đơn & Lịch Tập AI',
              desc: 'Tự động tính toán Calo/Macro & thiết lập lịch trình tối ưu với Gemini AI.',
            ),
            const SizedBox(height: 12),
            _buildFeatureTile(
              icon: Icons.medical_services_outlined,
              color: const Color(0xFFEF4444),
              title: 'Thích Ứng Chấn Thương & Dị Ứng',
              desc: 'Rà soát dị ứng thực phẩm và tự động tránh các bài tập ảnh hưởng vùng chấn thương.',
            ),
            const SizedBox(height: 12),
            _buildFeatureTile(
              icon: Icons.swap_horiz_rounded,
              color: const Color(0xFF10B981),
              title: 'Smart Swap Thông Minh',
              desc: 'Đổi món ăn & bài tập linh hoạt mà vẫn giữ nguyên mục tiêu Calo & dinh dưỡng.',
            ),
            const SizedBox(height: 12),
            _buildFeatureTile(
              icon: Icons.analytics_outlined,
              color: const Color(0xFFF59E0B),
              title: 'Phân Tích Sức Khỏe Chi Tiết',
              desc: 'Theo dõi BMI, BMR, TDEE, Calorie Balance và chuỗi ngày tập luyện (Streak).',
            ),
            const SizedBox(height: 32),

            // App Specs & Info
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _buildInfoRow('Phát triển bởi', 'Đội Ngũ DATN BodyPilot'),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  _buildInfoRow('Công nghệ AI', 'Google Gemini 1.5 Pro'),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  _buildInfoRow('Dữ liệu dinh dưỡng', 'OpenNutrition App'),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  _buildInfoRow('Dữ liệu bài tập', 'wrkout/exercises.json'),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  _buildInfoRow('Trạng thái hệ thống', 'Hoạt động ổn định', isSuccess: true),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  _buildInfoRow('Bản quyền', '© 2026 BodyPilot Inc.'),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Footer note
            Text(
              'BodyPilot - Đồng hành cùng hành trình vóc dáng của bạn.',
              style: GoogleFonts.workSans(
                fontSize: 12,
                color: const Color(0xFF94A3B8),
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureTile({
    required IconData icon,
    required Color color,
    required String title,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.workSans(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: GoogleFonts.workSans(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isSuccess = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.workSans(fontSize: 14, color: const Color(0xFF64748B)),
          ),
          Row(
            children: [
              if (isSuccess) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                value,
                style: GoogleFonts.workSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSuccess ? const Color(0xFF10B981) : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
