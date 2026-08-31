import 'package:core_shared/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/presentation/bloc/user/user_cubit.dart';
import 'package:mobile/presentation/widgets/hero_profile_avatar.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;
  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _fullNameController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  late TextEditingController _ageController;

  String _selectedGender = 'MALE';
  String _selectedActivityLevel = 'MODERATE';
  bool _hasExperience = false;
  bool _isSubmitting = false;

  final List<Map<String, String>> _genders = [
    {'value': 'MALE', 'label': 'Nam ♂'},
    {'value': 'FEMALE', 'label': 'Nữ ♀'},
    {'value': 'OTHER', 'label': 'Khác'},
  ];

  final List<Map<String, String>> _activityLevels = [
    {'value': 'SEDENTARY', 'label': 'Ít vận động (Ngồi văn phòng)'},
    {'value': 'LIGHT', 'label': 'Vận động nhẹ (Tập 1-3 ngày/tuần)'},
    {'value': 'MODERATE', 'label': 'Vận động vừa (Tập 3-5 ngày/tuần)'},
    {'value': 'VERY_ACTIVE', 'label': 'Vận động nhiều (Tập 6-7 ngày/tuần)'},
    {'value': 'EXTRA_ACTIVE', 'label': 'Vận động cường độ cao'},
  ];

  @override
  void initState() {
    super.initState();
    final profile = widget.user.profile;
    final metrics = widget.user.metrics;

    _fullNameController = TextEditingController(text: profile?.fullName ?? '');
    _weightController = TextEditingController(text: metrics?.weight?.toString() ?? '');
    _heightController = TextEditingController(text: metrics?.heightCm?.toInt().toString() ?? '');
    _ageController = TextEditingController(text: metrics?.age?.toString() ?? '');

    if (profile?.gender != null && profile!.gender!.isNotEmpty) {
      final gUpper = profile.gender!.toUpperCase();
      if (gUpper == 'MALE' || gUpper == 'NAM') {
        _selectedGender = 'MALE';
      } else if (gUpper == 'FEMALE' || gUpper == 'NU' || gUpper == 'NỮ') {
        _selectedGender = 'FEMALE';
      } else {
        _selectedGender = 'OTHER';
      }
    }

    if (profile?.hasExperience != null) {
      _hasExperience = profile!.hasExperience!;
    }

    if (metrics?.activityLevel != null) {
      _selectedActivityLevel = metrics!.activityLevel!;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveProfile() async {
    final name = _fullNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập họ và tên!'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final data = <String, dynamic>{
        'fullName': name,
        'gender': _selectedGender,
        'hasExperience': _hasExperience,
        'activityLevel': _selectedActivityLevel,
      };

      final weight = double.tryParse(_weightController.text.trim());
      if (weight != null) data['weight'] = weight;

      final height = double.tryParse(_heightController.text.trim());
      if (height != null) data['heightCm'] = height;

      final age = int.tryParse(_ageController.text.trim());
      if (age != null) data['age'] = age;

      final success = await context.read<UserCubit>().updateProfile(data);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật hồ sơ cá nhân thành công!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể cập nhật hồ sơ. Vui lòng thử lại!'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể cập nhật hồ sơ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = widget.user.profile?.avatarUrl;

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
          'Chỉnh Sửa Hồ Sơ',
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
            // Avatar Edit Header
            Center(
              child: Stack(
                children: [
                  HeroProfileAvatar(
                    avatarUrl: avatarUrl,
                    radius: 50,
                    heroTag: 'profile_avatar_edit',
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Tính năng tải ảnh đại diện sẽ sớm khả dụng!')),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Personal Info Form
            _buildSectionHeader('Thông Tin Cá Nhân'),
            const SizedBox(height: 14),
            _buildInputField('Họ và tên', _fullNameController, hint: 'Nhập họ và tên...'),
            const SizedBox(height: 16),
            _buildGenderSelector(),
            const SizedBox(height: 24),

            // Health & Metric Form
            _buildSectionHeader('Chỉ Số Thể Trạng'),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: _buildInputField('Cân nặng (kg)', _weightController, isNumber: true, hint: '70')),
                const SizedBox(width: 14),
                Expanded(child: _buildInputField('Chiều cao (cm)', _heightController, isNumber: true, hint: '175')),
                const SizedBox(width: 14),
                Expanded(child: _buildInputField('Tuổi', _ageController, isNumber: true, hint: '25')),
              ],
            ),
            const SizedBox(height: 16),
            _buildActivityLevelDropdown(),
            const SizedBox(height: 24),

            // Workout Experience Form
            _buildSectionHeader('Kinh Nghiệm Tập Luyện'),
            const SizedBox(height: 14),
            _buildExperienceSelector(),
            const SizedBox(height: 36),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSaveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Lưu Thay Đổi', style: GoogleFonts.workSans(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.workSans(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, {bool isNumber = false, String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.workSans(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: GoogleFonts.workSans(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.workSans(color: const Color(0xFF94A3B8)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Giới tính', style: GoogleFonts.workSans(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
        const SizedBox(height: 6),
        Row(
          children: _genders.map((g) {
            final isSelected = _selectedGender == g['value'];
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: InkWell(
                  onTap: () => setState(() => _selectedGender = g['value']!),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primary : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? AppTheme.primary : const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      g['label']!,
                      style: GoogleFonts.workSans(fontSize: 13, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : const Color(0xFF475569)),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActivityLevelDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mức độ vận động', style: GoogleFonts.workSans(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedActivityLevel,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
              items: _activityLevels.map((lvl) {
                return DropdownMenuItem<String>(
                  value: lvl['value'],
                  child: Text(lvl['label']!, style: GoogleFonts.workSans(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF1E293B))),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedActivityLevel = val);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExperienceSelector() {
    return Row(
      children: [
        // Beginner option
        Expanded(
          child: InkWell(
            onTap: () => setState(() => _hasExperience = false),
            borderRadius: BorderRadius.circular(14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              decoration: BoxDecoration(
                color: !_hasExperience ? AppTheme.primary.withValues(alpha: 0.08) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: !_hasExperience ? AppTheme.primary : const Color(0xFFE2E8F0),
                  width: !_hasExperience ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: !_hasExperience ? AppTheme.primary : const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.spa_rounded,
                      size: 20,
                      color: !_hasExperience ? Colors.white : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Chưa từng tập',
                    style: GoogleFonts.workSans(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: !_hasExperience ? AppTheme.primary : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Người mới bắt đầu',
                    style: GoogleFonts.workSans(
                      fontSize: 11,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Experienced option
        Expanded(
          child: InkWell(
            onTap: () => setState(() => _hasExperience = true),
            borderRadius: BorderRadius.circular(14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              decoration: BoxDecoration(
                color: _hasExperience ? AppTheme.primary.withValues(alpha: 0.08) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _hasExperience ? AppTheme.primary : const Color(0xFFE2E8F0),
                  width: _hasExperience ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _hasExperience ? AppTheme.primary : const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.fitness_center_rounded,
                      size: 20,
                      color: _hasExperience ? Colors.white : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Đã từng tập',
                    style: GoogleFonts.workSans(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _hasExperience ? AppTheme.primary : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Đã có kinh nghiệm',
                    style: GoogleFonts.workSans(
                      fontSize: 11,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
