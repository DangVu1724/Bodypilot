import 'package:core_shared/models/user_metrics_model.dart';
import 'package:core_shared/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/routes/app_routes.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/data/repositories/auth_repository.dart';
import 'package:mobile/data/services/token_service.dart';
import 'package:mobile/presentation/bloc/food/food_cubit.dart';
import 'package:mobile/presentation/bloc/user/user_cubit.dart';
import 'package:mobile/presentation/bloc/user/user_state.dart';
import 'package:mobile/presentation/screens/assessment/assessment_screen.dart';
import 'package:mobile/presentation/screens/profile/about_screen.dart';
import 'package:mobile/presentation/screens/profile/edit_profile_screen.dart';
import 'package:mobile/presentation/screens/profile/help_center_screen.dart';
import 'package:mobile/presentation/screens/profile/privacy_screen.dart';
import 'package:mobile/presentation/screens/profile/scientific_basis_screen.dart';
import 'package:mobile/presentation/widgets/hero_profile_avatar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFA0AEC0), // Slate Grey
              Color(0xFFD6CCC2), // Warm Beige
            ],
          ),
        ),
        child: BlocBuilder<UserCubit, UserState>(
          builder: (context, state) {
            if (state is UserLoading) {
              return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
            } else if (state is UserLoaded) {
              return _buildProfileContent(context, state.user);
            } else if (state is UserError) {
              return Center(child: Text('Lỗi: ${state.message}'));
            }
            return const Center(child: Text('Không tìm thấy dữ liệu người dùng'));
          },
        ),
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, UserModel user) {
    final profile = user.profile;
    final metrics = user.metrics;
    final goal = user.goal;

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề cố định ở đỉnh màn hình
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
            child: Text('Hồ Sơ Cá Nhân', style: AppTheme.headlineStyle.copyWith(fontSize: 24, letterSpacing: -0.5)),
          ),

          // Nội dung cuộn bên dưới
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  _buildHeader(profile?.fullName ?? 'Người dùng', user.email, profile?.avatarUrl),
                  const SizedBox(height: 32),

                  _buildHighlightMetricsCard(metrics),
                  const SizedBox(height: 32),

                  _buildSectionTitle('Mục Tiêu Hiện Tại'),
                  const SizedBox(height: 16),
                  _buildGoalCard(context, goal, metrics?.weight),
                  const SizedBox(height: 32),

                  _buildSectionTitle('Chỉ Số Sức Khỏe'),
                  const SizedBox(height: 16),
                  _buildAdvancedMetricsGrid(metrics),
                  const SizedBox(height: 32),

                  _buildSettingsGroup('TÀI KHOẢN', [
                    _buildSettingsTile(Icons.person_outline, 'Chỉnh Sửa Hồ Sơ', () {
                      Navigator.of(
                        context,
                        rootNavigator: true,
                      ).push(MaterialPageRoute(builder: (context) => EditProfileScreen(user: user)));
                    }),
                    _buildSettingsTile(Icons.assignment_outlined, 'Làm Lại Khảo Sát Thể Trạng', () {
                      Navigator.of(
                        context,
                        rootNavigator: true,
                      ).push(MaterialPageRoute(builder: (context) => const AssessmentScreen()));
                    }),
                    _buildSettingsTile(
                      Icons.notifications_none,
                      'Thông Báo',
                      () => context.push(AppRoutes.notifications),
                    ),
                    _buildSettingsTile(Icons.security, 'Quyền Riêng Tư & Bảo Mật', () {
                      Navigator.of(
                        context,
                        rootNavigator: true,
                      ).push(MaterialPageRoute(builder: (context) => const PrivacyScreen()));
                    }),
                  ]),
                  const SizedBox(height: 24),
                  _buildSettingsGroup('HỖ TRỢ', [
                    _buildSettingsTile(Icons.science_outlined, 'Cơ Sở Khoa Học & Dữ Liệu', () {
                      Navigator.of(
                        context,
                        rootNavigator: true,
                      ).push(MaterialPageRoute(builder: (context) => const ScientificBasisScreen()));
                    }),
                    _buildSettingsTile(Icons.help_outline, 'Trung Tâm Trợ Giúp', () {
                      Navigator.of(
                        context,
                        rootNavigator: true,
                      ).push(MaterialPageRoute(builder: (context) => const HelpCenterScreen()));
                    }),
                    _buildSettingsTile(Icons.info_outline, 'Về BodyPilot', () {
                      Navigator.of(
                        context,
                        rootNavigator: true,
                      ).push(MaterialPageRoute(builder: (context) => const AboutScreen()));
                    }),
                  ]),
                  const SizedBox(height: 24),
                  _buildSettingsGroup('ĐĂNG XUẤT', [
                    _buildSettingsTile(Icons.logout, 'Đăng Xuất', () => _showLogoutDialog(context), isDanger: true),
                  ], showDivider: false),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String name, String email, String? avatarUrl) {
    final streakDays = TokenService.getStreakCount();

    return Row(
      children: [
        HeroProfileAvatar(
          avatarUrl: avatarUrl,
          radius: 60,
          heroTag: 'profile_avatar',
          border: Border.all(color: Colors.white, width: 4),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: AppTheme.headlineStyle.copyWith(fontSize: 22, height: 1.2)),
              const SizedBox(height: 4),
              Text(email, style: AppTheme.bodyStyle.copyWith(color: AppTheme.textSecondary, fontSize: 14)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: const Color(0xFFFCD34D).withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      'Chuỗi $streakDays Ngày',
                      style: AppTheme.semiboldStyle.copyWith(fontSize: 12, color: const Color(0xFFB45309)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHighlightMetricsCard(UserMetricsModel? metrics) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 24, offset: const Offset(0, 12))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildMetricItem('Cân nặng', '${metrics?.weight ?? '--'}', 'kg'),
          _buildVerticalDivider(),
          _buildMetricItem('Chiều cao', '${metrics?.heightCm?.toInt() ?? '--'}', 'cm'),
          _buildVerticalDivider(),
          _buildMetricItem('Tuổi', '${metrics?.age ?? '--'}', 'tuổi'),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, String unit) {
    return Column(
      children: [
        Text(label, style: AppTheme.bodyStyle.copyWith(color: AppTheme.textSecondary, fontSize: 13)),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: AppTheme.semiboldStyle.copyWith(fontSize: 22, color: AppTheme.textPrimary),
              ),
              const WidgetSpan(child: SizedBox(width: 2)),
              TextSpan(
                text: unit,
                style: AppTheme.bodyStyle.copyWith(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(height: 32, width: 1.5, color: const Color(0xFFF1F5F9));
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(title, style: AppTheme.semiboldStyle.copyWith(fontSize: 18, color: AppTheme.textPrimary)),
    );
  }

  Widget _buildGoalCard(BuildContext context, dynamic goal, double? currentWeight) {
    final rawType = (goal?.type ?? '').toString().toUpperCase();
    final isMaintain = rawType.contains('MAINTAIN') || rawType.contains('DUY_TRI');

    final displayType = (goal?.type != null && goal.type.toString().isNotEmpty) ? goal.type.toString() : 'GAIN_MUSCLE';
    final targetWeight = (goal?.targetWeight as num?)?.toDouble() ?? 65.0;

    // Calculate Estimated Completion Date based on 0.5 kg / week
    String? estimatedCompletionDateStr;
    if (!isMaintain && currentWeight != null && (currentWeight - targetWeight).abs() > 0.1) {
      final weightDiff = (targetWeight - currentWeight).abs();
      final weeksNeeded = weightDiff / 0.5;
      final daysNeeded = (weeksNeeded * 7).ceil();
      final estimatedDate = DateTime.now().add(Duration(days: daysNeeded));
      estimatedCompletionDateStr = DateFormat('dd/MM/yyyy').format(estimatedDate);
    }

    // Calculate dynamic progress towards target weight
    double progress = 1.0;
    if (isMaintain) {
      progress = 1.0;
    } else if (currentWeight != null && currentWeight > 0 && targetWeight > 0) {
      if (rawType.contains('LOSE') || rawType.contains('CUT') || rawType.contains('GIAM')) {
        if (currentWeight <= targetWeight) {
          progress = 1.0;
        } else {
          progress = (targetWeight / currentWeight).clamp(0.0, 1.0);
        }
      } else {
        if (currentWeight >= targetWeight) {
          progress = 1.0;
        } else {
          progress = (currentWeight / targetWeight).clamp(0.0, 1.0);
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Icon + Title & Target + Percentage
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFF0F172A),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.fitness_center_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayType,
                      style: GoogleFonts.workSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Target: ${targetWeight.toStringAsFixed(1)} kg',
                      style: GoogleFonts.workSans(
                        fontSize: 13,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: GoogleFonts.workSans(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFF6B2C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF6B2C)),
            ),
          ),
          const SizedBox(height: 20),

          // Info Rows: Target & Estimated Completion Date
          Column(
            children: [
              // Row 1: Target
              Row(
                children: [
                  const Icon(Icons.track_changes_rounded, color: Color(0xFF0F172A), size: 22),
                  const SizedBox(width: 12),
                  Text(
                    'Mục tiêu',
                    style: GoogleFonts.workSans(
                      fontSize: 14,
                      color: const Color(0xFF0F172A),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${targetWeight.toStringAsFixed(1)} kg',
                    style: GoogleFonts.workSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),

              // Row 2: Estimated Completion Date
              if (!isMaintain && estimatedCompletionDateStr != null) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                ),
                Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded, color: Color(0xFF0F172A), size: 22),
                    const SizedBox(width: 12),
                    Text(
                      'Dự kiến hoàn thành',
                      style: GoogleFonts.workSans(
                        fontSize: 14,
                        color: const Color(0xFF0F172A),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      estimatedCompletionDateStr,
                      style: GoogleFonts.workSans(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),

          // Action Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => _showUpdateGoalBottomSheet(context, goal, currentWeight),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                'Cập nhật tiến độ',
                style: GoogleFonts.workSans(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedMetricsGrid(UserMetricsModel? metrics) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.35,
      children: [
        _buildMetricCard('BMI', metrics?.bmi?.toStringAsFixed(1) ?? '--', 'Chỉ số', Icons.speed),
        _buildMetricCard('BMR', metrics?.bmr?.toInt().toString() ?? '--', 'kcal/ngày', Icons.local_fire_department),
        _buildMetricCard('TDEE', metrics?.tdee?.toInt().toString() ?? '--', 'kcal/ngày', Icons.flash_on),
        _buildMetricCard('Calo/Ngày', metrics?.targetCalories?.toInt().toString() ?? '--', 'kcal', Icons.restaurant),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, String unit, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0).withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTheme.bodyStyle.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(icon, size: 18, color: AppTheme.primary.withOpacity(0.5)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: AppTheme.semiboldStyle.copyWith(fontSize: 20, letterSpacing: -0.5)),
              const SizedBox(height: 2),
              Text(unit, style: AppTheme.bodyStyle.copyWith(fontSize: 11, color: AppTheme.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(String title, List<Widget> tiles, {bool showDivider = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: AppTheme.semiboldStyle.copyWith(fontSize: 14, color: AppTheme.textSecondary, letterSpacing: 1),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Column(children: tiles),
        ),
      ],
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, VoidCallback onTap, {bool isDanger = false}) {
    final color = isDanger ? const Color(0xFFEF4444) : AppTheme.textPrimary;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: AppTheme.bodyStyle.copyWith(fontWeight: FontWeight.w600, color: color, fontSize: 15),
      ),
      trailing: Icon(Icons.chevron_right_rounded, size: 22, color: color.withOpacity(0.3)),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  void _showUpdateGoalBottomSheet(BuildContext context, dynamic goal, double? currentWeight) {
    final weightController = TextEditingController(text: currentWeight?.toString() ?? '');
    final targetWeightController = TextEditingController(text: goal?.targetWeight?.toString() ?? '');

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
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Cập Nhật Mục Tiêu & Cân Nặng',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 6),
              const Text(
                'Nhập số cân nặng mới nhất để hệ thống tính lại Calo & tiến độ.',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: weightController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Cân nặng hiện tại (kg)',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: targetWeightController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Cân nặng mục tiêu (kg)',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    final newWeight = double.tryParse(weightController.text.trim());
                    final newTargetWeight = double.tryParse(targetWeightController.text.trim());

                    if (newWeight != null || newTargetWeight != null) {
                      context.read<UserCubit>().updateGoalAndWeight(
                        newWeight: newWeight,
                        newTargetWeight: newTargetWeight,
                      );
                    }

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã cập nhật tiến độ mục tiêu thành công!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('Cập Nhật Tiến Độ', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text('Đăng xuất', style: AppTheme.headlineStyle.copyWith(fontSize: 18)),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi tài khoản không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy', style: AppTheme.semiboldStyle.copyWith(color: AppTheme.textSecondary)),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: ElevatedButton(
              onPressed: () async {
                context.read<UserCubit>().clear();
                context.read<FoodCubit>().clear();

                await authRepository.logout();
                if (context.mounted) {
                  context.go(AppRoutes.welcome);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: const Text('Đăng xuất'),
            ),
          ),
        ],
      ),
    );
  }
}
