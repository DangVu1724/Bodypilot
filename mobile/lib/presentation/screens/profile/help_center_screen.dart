import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/theme/app_theme.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'Tất cả';

  final List<String> _categories = [
    'Tất cả',
    'Thực đơn AI',
    'Lịch tập AI',
    'Chỉ số Calo',
    'Tài khoản',
  ];

  final List<Map<String, String>> _faqs = [
    {
      'category': 'Thực đơn AI',
      'question': 'AI gợi ý thực đơn hoạt động như thế nào?',
      'answer':
          'BodyPilot thu thập thông tin cân nặng, chiều cao, BMR, Calo mục tiêu kết hợp với danh sách dị ứng thực phẩm và chế độ ăn của bạn. Sau đó Gemini AI sẽ thiết lập thực đơn chi tiết từng món ăn đảm bảo đủ Calo và Macro.',
    },
    {
      'category': 'Thực đơn AI',
      'question': 'Tôi muốn thay đổi món ăn không thích trong thực đơn AI?',
      'answer':
          'Khi xem trước thực đơn AI, bạn có thể nhập phản hồi (ví dụ: "Tôi không thích ăn cá") và bấm tạo lại. Ngoài ra, bạn cũng có thể dùng tính năng Smart Swap để đổi món ăn tương đương.',
    },
    {
      'category': 'Lịch tập AI',
      'question': 'Làm sao để AI tránh các bài tập ảnh hưởng chấn thương của tôi?',
      'answer':
          'Hãy đảm bảo bạn đã hoàn thành khảo sát chấn thương trong hồ sơ. AI sẽ tự động rà soát cơ sở dữ liệu bài tập và loại bỏ tất cả bài tập tác động xấu đến vùng cơ/khớp bị chấn thương của bạn.',
    },
    {
      'category': 'Chỉ số Calo',
      'question': 'BMI, BMR và TDEE được tính dựa trên công thức nào?',
      'answer':
          'BMR được tính theo công thức Mifflin-St Jeor chuẩn quốc tế dựa trên tuổi, giới tính, chiều cao và cân nặng. TDEE được tính bằng BMR nhân hệ số vận động PAL của bạn.',
    },
    {
      'category': 'Chỉ số Calo',
      'question': 'Tính năng Streak (Chuỗi ngày) hoạt động ra sao?',
      'answer':
          'Mỗi ngày bạn hoàn thành việc điểm danh check-in, ghi chép nhật ký ăn uống hoặc tập luyện, Streak sẽ tăng thêm 1 ngày. Đừng bỏ lỡ quá 1 ngày nhé!',
    },
    {
      'category': 'Tài khoản',
      'question': 'Làm thế nào để đổi thông tin cá nhân hoặc mục tiêu?',
      'answer':
          'Bạn truy cập vào trang Profile, bấm vào mục "Edit Profile" để cập nhật họ tên, chiều cao, cân nặng cũng như mục tiêu Tăng cân / Giảm cân bất kỳ lúc nào.',
    },
  ];

  void _showFeedbackModal() {
    final feedbackController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      backgroundColor: Colors.white,
      builder: (context) {
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
              Text(
                'Gửi Phản Hồi Cho Đội Ngũ BodyPilot',
                style: GoogleFonts.workSans(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
              ),
              const SizedBox(height: 6),
              Text(
                'Chúng tôi luôn lắng nghe ý kiến đóng góp của bạn để hoàn thiện hơn.',
                style: GoogleFonts.workSans(fontSize: 13, color: const Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: feedbackController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Nhập ý kiến đóng góp hoặc lỗi bạn gặp phải...',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    if (feedbackController.text.trim().isEmpty) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cảm ơn bạn đã gửi phản hồi! Chúng tôi sẽ phản hồi sớm nhất.'), backgroundColor: Colors.green),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text('Gửi Phản Hồi', style: GoogleFonts.workSans(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredFaqs = _faqs.where((faq) {
      final matchesCat = _selectedCategory == 'Tất cả' || faq['category'] == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          faq['question']!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          faq['answer']!.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCat && matchesSearch;
    }).toList();

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
          'Trung Tâm Hỗ Trợ',
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
            // Search Input Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF07025), Color(0xFFFF8E42)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: const Color(0xFFF07025).withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 8)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chúng tôi có thể giúp gì cho bạn?',
                    style: GoogleFonts.workSans(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm câu hỏi, vấn đề...',
                        hintStyle: GoogleFonts.workSans(fontSize: 14, color: const Color(0xFF94A3B8)),
                        prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primary),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Category filter chips
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategory == cat;
                  return ChoiceChip(
                    label: Text(cat, style: GoogleFonts.workSans(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
                    selected: isSelected,
                    selectedColor: const Color(0xFF1E293B),
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : const Color(0xFF64748B)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100), side: BorderSide(color: isSelected ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0))),
                    onSelected: (val) {
                      if (val) setState(() => _selectedCategory = cat);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // FAQ List
            Text('Câu Hỏi Thường Gặp (${filteredFaqs.length})', style: GoogleFonts.workSans(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
            const SizedBox(height: 12),

            if (filteredFaqs.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Column(
                  children: [
                    const Icon(Icons.help_center_outlined, size: 48, color: Color(0xFF94A3B8)),
                    const SizedBox(height: 12),
                    Text('Không tìm thấy câu hỏi phù hợp', style: GoogleFonts.workSans(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredFaqs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = filteredFaqs[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: ExpansionTile(
                      title: Text(item['question']!, style: GoogleFonts.workSans(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      children: [
                        Text(
                          item['answer']!,
                          style: GoogleFonts.workSans(fontSize: 13, color: const Color(0xFF64748B), height: 1.5),
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 32),

            // Contact Support Options
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.headset_mic_rounded, color: AppTheme.primary, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Chưa tìm thấy câu trả lời?', style: GoogleFonts.workSans(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                            const SizedBox(height: 2),
                            Text('Đội ngũ hỗ trợ BodyPilot luôn sẵn sàng giúp đỡ bạn.', style: GoogleFonts.workSans(fontSize: 12, color: const Color(0xFF64748B))),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _showFeedbackModal,
                          icon: const Icon(Icons.rate_review_outlined, size: 18),
                          label: const Text('Gửi Phản Hồi'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1E293B),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Email hỗ trợ: support@bodypilot.com'), backgroundColor: Colors.blue),
                            );
                          },
                          icon: const Icon(Icons.email_outlined, size: 18),
                          label: const Text('Email Hỗ Trợ'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E293B),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
