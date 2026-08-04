import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/theme/app_theme.dart';

class ScientificBasisScreen extends StatelessWidget {
  const ScientificBasisScreen({super.key});

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
          'Cơ Sở Khoa Học & Dữ Liệu',
          style: GoogleFonts.workSans(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Medical Disclaimer Banner (Mandatory AI Notice)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFFCD34D)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD97706).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Khuyến Cáo Y Tế & AI Disclaimer',
                          style: GoogleFonts.workSans(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF92400E)),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Các gợi ý thực đơn, bài tập và tính toán calo do BodyPilot AI tạo ra mang tính chất tham khảo khoa học và đề xuất cá nhân hóa. AI không thay thế cho chẩn đoán, tư vấn y khoa chuyên sâu hoặc phác đồ điều trị từ bác sĩ/chuyên gia dinh dưỡng.',
                          style: GoogleFonts.workSans(fontSize: 13, color: const Color(0xFFB45309), height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Section 1: Scientific Formulas
            _buildSectionHeader('1. Công Thức Đo Lường Thể Trạng'),
            const SizedBox(height: 12),
            _buildScientificCard(
              icon: Icons.local_fire_department_rounded,
              color: const Color(0xFFF07025),
              title: 'Công thức Mifflin-St Jeor (BMR)',
              desc: 'Được Hiệp hội Dinh dưỡng Hoa Kỳ (AND) công nhận là công thức đo tỷ lệ trao đổi chất cơ bản BMR chính xác nhất hiện nay.',
              formula: 'Nam: BMR = 10W + 6.25H - 5A + 5\nNữ: BMR = 10W + 6.25H - 5A - 161\n(W: Cân nặng kg, H: Chiều cao cm, A: Tuổi)',
            ),
            const SizedBox(height: 12),
            _buildScientificCard(
              icon: Icons.flash_on_rounded,
              color: const Color(0xFF8B5CF6),
              title: 'Hệ Số Năng Lượng TDEE & PAL (WHO)',
              desc: 'Tổng năng lượng tiêu thụ hàng ngày TDEE được tính dựa trên hệ số vận động PAL tiêu chuẩn của Tổ chức Y tế Thế giới (WHO).',
              formula: 'TDEE = BMR × PAL (PAL từ 1.2 - Ít vận động đến 1.9 - Cường độ cao)',
            ),
            const SizedBox(height: 12),
            _buildScientificCard(
              icon: Icons.speed_rounded,
              color: const Color(0xFF10B981),
              title: 'Chỉ Số BMI & Chuẩn Thể Trạng Châu Á',
              desc: 'Đánh giá mức độ thiếu cân, bình thường hoặc thừa cân theo bảng phân loại BMI dành riêng cho người châu Á (WHO WPRO).',
              formula: 'BMI = Cân nặng (kg) / (Chiều cao (m))²',
            ),
            const SizedBox(height: 28),

            // Section 2: Data Sources
            _buildSectionHeader('2. Nguồn Dữ Liệu Dinh Dưỡng & Bài Tập'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _buildSourceRow(
                    icon: Icons.restaurant_menu_rounded,
                    color: const Color(0xFF10B981),
                    title: 'Dữ Liệu Dinh Dưỡng Open Nutrition',
                    desc: 'Dữ liệu thành phần dinh dưỡng, calo và macro của các món ăn được khai thác từ CSDL mở Open Nutrition App (opennutrition.app/about).',
                  ),
                  const Divider(height: 24, color: Color(0xFFF1F5F9)),
                  _buildSourceRow(
                    icon: Icons.fitness_center_rounded,
                    color: const Color(0xFF3B82F6),
                    title: 'Dữ Liệu Bài Tập Public Domain (wrkout/exercises.json)',
                    desc: 'Cơ sở dữ liệu bài tập thể thao, nhóm cơ tác động và hướng dẫn kỹ thuật trích xuất từ Open Public Domain Exercise Dataset (github.com/wrkout/exercises.json & wrkout.xyz).',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Section 3: Safety & AI Algorithmic Standards
            _buildSectionHeader('3. Thuật Toán Lọc An Toàn Chấn Thương & Dị Ứng'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBulletPoint('Kháng dị ứng cứng (Hard Filtering): Loại bỏ 100% nguyên liệu nằm trong danh sách dị ứng được người dùng khai báo.'),
                  const SizedBox(height: 10),
                  _buildBulletPoint('Bảo vệ khớp & chấn thương: Loại trừ các bài tập chịu áp lực lớn lên vùng cơ/khớp đang bị chấn thương (gối, lưng, vai...).'),
                  const SizedBox(height: 10),
                  _buildBulletPoint('Cân đối Macro chuẩn y khoa: Phân bổ Calo các bữa ăn theo tỷ lệ 30% Sáng - 35% Trưa - 25% Tối - 10% Phụ.'),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.workSans(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
    );
  }

  Widget _buildScientificCard({
    required IconData icon,
    required Color color,
    required String title,
    required String desc,
    required String formula,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.workSans(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            desc,
            style: GoogleFonts.workSans(fontSize: 13, color: const Color(0xFF64748B), height: 1.5),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              formula,
              style: GoogleFonts.firaCode(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF334155), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceRow({required IconData icon, required Color color, required String title, required String desc}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.workSans(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
              const SizedBox(height: 4),
              Text(desc, style: GoogleFonts.workSans(fontSize: 13, color: const Color(0xFF64748B), height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBulletPoint(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('• ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primary)),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.workSans(fontSize: 13, color: const Color(0xFF475569), height: 1.4),
          ),
        ),
      ],
    );
  }
}
