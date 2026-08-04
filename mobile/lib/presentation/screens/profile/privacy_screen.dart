import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/theme/app_theme.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  bool _biometricEnabled = true;
  bool _shareAnonymousData = false;
  bool _securityAlerts = true;

  void _showChangePasswordBottomSheet() {
    final currentPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Đổi Mật Khẩu',
                    style: GoogleFonts.workSans(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Mật khẩu mới phải có ít nhất 6 ký tự.',
                    style: GoogleFonts.workSans(fontSize: 13, color: const Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 20),
                  _buildPasswordField('Mật khẩu hiện tại', currentPassController),
                  const SizedBox(height: 14),
                  _buildPasswordField('Mật khẩu mới', newPassController),
                  const SizedBox(height: 14),
                  _buildPasswordField('Xác nhận mật khẩu mới', confirmPassController),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () async {
                              final current = currentPassController.text.trim();
                              final newP = newPassController.text.trim();
                              final confirm = confirmPassController.text.trim();

                              if (current.isEmpty || newP.isEmpty || confirm.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Vui lòng nhập đầy đủ các trường!'), backgroundColor: Colors.red),
                                );
                                return;
                              }
                              if (newP.length < 6) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Mật khẩu mới phải dài từ 6 ký tự!'), backgroundColor: Colors.red),
                                );
                                return;
                              }
                              if (newP != confirm) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Mật khẩu xác nhận không trùng khớp!'), backgroundColor: Colors.red),
                                );
                                return;
                              }

                              setModalState(() => isLoading = true);
                              await Future.delayed(const Duration(seconds: 1));
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Đổi mật khẩu thành công!'), backgroundColor: Colors.green),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text('Cập Nhật Mật Khẩu', style: GoogleFonts.workSans(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.workSans(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: true,
          decoration: InputDecoration(
            hintText: '••••••••',
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
          ),
        ),
      ],
    );
  }

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
          'Quyền Riêng Tư & Bảo Mật',
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
            // Shield Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF334155)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF1E293B).withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 8)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 36),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dữ Liệu Được Bảo Vệ 100%',
                          style: GoogleFonts.workSans(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Mọi thông tin chỉ số cơ thể & lịch trình ăn uống của bạn được mã hóa an toàn.',
                          style: GoogleFonts.workSans(fontSize: 12, color: const Color(0xFF94A3B8), height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Security Controls Title
            Text('Cài Đặt An Toàn', style: GoogleFonts.workSans(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    activeColor: AppTheme.primary,
                    title: Text('Xác thực sinh trắc học (FaceID / Fingerprint)', style: GoogleFonts.workSans(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
                    subtitle: Text('Yêu cầu quét vân tay hoặc khuôn mặt khi mở app.', style: GoogleFonts.workSans(fontSize: 12, color: const Color(0xFF64748B))),
                    value: _biometricEnabled,
                    onChanged: (val) => setState(() => _biometricEnabled = val),
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  SwitchListTile(
                    activeColor: AppTheme.primary,
                    title: Text('Cảnh báo đăng nhập bất thường', style: GoogleFonts.workSans(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
                    subtitle: Text('Gửi thông báo ngay khi có thiết bị lạ đăng nhập.', style: GoogleFonts.workSans(fontSize: 12, color: const Color(0xFF64748B))),
                    value: _securityAlerts,
                    onChanged: (val) => setState(() => _securityAlerts = val),
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  SwitchListTile(
                    activeColor: AppTheme.primary,
                    title: Text('Chia sẻ dữ liệu ẩn danh để huấn luyện AI', style: GoogleFonts.workSans(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
                    subtitle: Text('Giúp AI gợi ý món ăn & bài tập chính xác hơn.', style: GoogleFonts.workSans(fontSize: 12, color: const Color(0xFF64748B))),
                    value: _shareAnonymousData,
                    onChanged: (val) => setState(() => _shareAnonymousData = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Account Actions
            Text('Hành Động Bảo Mật', style: GoogleFonts.workSans(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _buildActionTile(
                    icon: Icons.lock_reset_rounded,
                    title: 'Đổi Mật Khẩu',
                    subtitle: 'Cập nhật mật khẩu truy cập tài khoản',
                    onTap: _showChangePasswordBottomSheet,
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  _buildActionTile(
                    icon: Icons.download_for_offline_rounded,
                    title: 'Tải Xuống Dữ Liệu Cá Nhân',
                    subtitle: 'Xuất dữ liệu cân nặng, calo & lịch tập (JSON/CSV)',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Hệ thống đang chuẩn bị tệp dữ liệu cá nhân của bạn...'), backgroundColor: Colors.blue),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Privacy Policy Agreements
            Text('Chính Sách & Quy Định', style: GoogleFonts.workSans(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
            const SizedBox(height: 12),
            _buildPolicyExpansion(
              'Thu thập và xử lý dữ liệu',
              'BodyPilot thu thập thông tin chiều cao, cân nặng, độ tuổi, các món ăn bạn ghi chép và danh sách bài tập thực hiện để tính toán chỉ số BMI, BMR, TDEE và gợi ý dinh dưỡng từ AI.',
            ),
            const SizedBox(height: 10),
            _buildPolicyExpansion(
              'Quyền lưu trữ dữ liệu y tế & chấn thương',
              'Thông tin chấn thương và dị ứng của bạn được lưu trữ ở chế độ riêng tư tuyệt đối, chỉ phục vụ việc loại trừ các món ăn gây dị ứng và bài tập chống chỉ định.',
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: AppTheme.primary, size: 22),
      ),
      title: Text(title, style: GoogleFonts.workSans(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
      subtitle: Text(subtitle, style: GoogleFonts.workSans(fontSize: 12, color: const Color(0xFF64748B))),
      trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 22),
      onTap: onTap,
    );
  }

  Widget _buildPolicyExpansion(String title, String content) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ExpansionTile(
        title: Text(title, style: GoogleFonts.workSans(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(
            content,
            style: GoogleFonts.workSans(fontSize: 13, color: const Color(0xFF64748B), height: 1.5),
          ),
        ],
      ),
    );
  }
}
