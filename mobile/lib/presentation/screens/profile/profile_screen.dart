import 'package:core_shared/models/user_metrics_model.dart';
import 'package:core_shared/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/presentation/bloc/user/user_cubit.dart';
import 'package:mobile/presentation/bloc/user/user_state.dart';
import 'package:mobile/data/repositories/auth_repository.dart';
import 'package:mobile/core/routes/app_routes.dart';
import 'package:mobile/presentation/bloc/food/food_cubit.dart';

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
              return Center(child: Text('Error: ${state.message}'));
            }
            return const Center(child: Text('No user data found'));
          },
        ),
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, UserModel user) {
    final profile = user.profile;
    final metrics = user.metrics;
    final goal = user.goal;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          expandedHeight: 100,
          floating: false,
          pinned: true,
          stretch: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            title: Text('Profile', style: AppTheme.headlineStyle.copyWith(fontSize: 24, letterSpacing: -0.5)),
          ),
          automaticallyImplyLeading: false,
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. User Header with Avatar, Name, Email, and Streak Badge
                _buildHeader(profile?.fullName ?? 'User', user.email, profile?.avatarUrl),
                const SizedBox(height: 32),

                // 2. Highlight Card for Weight, Height, Age
                _buildHighlightMetricsCard(metrics),
                const SizedBox(height: 32),

                // 3. Goal Card with Progress Bar and CTA
                _buildSectionTitle('Current Goal'),
                const SizedBox(height: 16),
                _buildGoalCard(goal, metrics?.weight),
                const SizedBox(height: 32),

                // 4. Grid of Advanced Metrics
                _buildSectionTitle('Health Metrics'),
                const SizedBox(height: 16),
                _buildAdvancedMetricsGrid(metrics),
                const SizedBox(height: 32),

                // 5. Grouped Account Settings with Danger Zone
                _buildSettingsGroup('Account', [
                  _buildSettingsTile(Icons.person_outline, 'Edit Profile', () {}),
                  _buildSettingsTile(Icons.notifications_none, 'Notifications', () {}),
                  _buildSettingsTile(Icons.security, 'Privacy & Security', () {}),
                ]),
                const SizedBox(height: 24),
                _buildSettingsGroup('Support', [
                  _buildSettingsTile(Icons.help_outline, 'Help Center', () {}),
                  _buildSettingsTile(Icons.info_outline, 'About BodyPilot', () {}),
                ]),
                const SizedBox(height: 24),
                _buildSettingsGroup('Danger Zone', [
                  _buildSettingsTile(Icons.logout, 'Logout', () => _showLogoutDialog(context), isDanger: true),
                  _buildSettingsTile(Icons.delete_forever_outlined, 'Delete Account', () {}, isDanger: true),
                ], showDivider: false),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(String name, String email, String? avatarUrl) {
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
              // Streak Badge
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
                      '15 Day Streak',
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
          _buildMetricItem('Weight', '${metrics?.weight ?? '--'}', 'kg'),
          _buildVerticalDivider(),
          _buildMetricItem('Height', '${metrics?.heightCm?.toInt() ?? '--'}', 'cm'),
          _buildVerticalDivider(),
          _buildMetricItem('Age', '${metrics?.age ?? '--'}', 'yo'),
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

  Widget _buildGoalCard(dynamic goal, double? currentWeight) {
    final type = goal?.type ?? 'No active goal';
    final targetWeight = goal?.targetWeight;
    double progress = 0.65; // Mock progress

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary.withOpacity(0.08), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.primary.withOpacity(0.12)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.bolt_rounded, color: AppTheme.primary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(type, style: AppTheme.semiboldStyle.copyWith(fontSize: 18)),
                    const SizedBox(height: 2),
                    Text(
                      targetWeight != null ? 'Target: $targetWeight kg' : 'Tap to set target',
                      style: AppTheme.bodyStyle.copyWith(color: AppTheme.textSecondary, fontSize: 14),
                    ),
                  ],
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: AppTheme.semiboldStyle.copyWith(color: AppTheme.primary, fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: AppTheme.primary.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Update Progress'),
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
        _buildMetricCard('BMI', metrics?.bmi?.toStringAsFixed(1) ?? '--', 'Index', Icons.speed),
        _buildMetricCard('BMR', metrics?.bmr?.toInt().toString() ?? '--', 'kcal/day', Icons.local_fire_department),
        _buildMetricCard('TDEE', metrics?.tdee?.toInt().toString() ?? '--', 'kcal/day', Icons.flash_on),
        _buildMetricCard('Daily Cal', metrics?.targetCalories?.toInt().toString() ?? '--', 'kcal', Icons.restaurant),
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

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text('Logout', style: AppTheme.headlineStyle.copyWith(fontSize: 18)),
        content: const Text('Are you sure you want to sign out from your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: AppTheme.semiboldStyle.copyWith(color: AppTheme.textSecondary)),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: ElevatedButton(
              onPressed: () async {
                context.read<UserCubit>().clear();
                context.read<FoodCubit>().clear();

                await authRepository.logout();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.welcome, (route) => false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: const Text('Logout'),
            ),
          ),
        ],
      ),
    );
  }
}
