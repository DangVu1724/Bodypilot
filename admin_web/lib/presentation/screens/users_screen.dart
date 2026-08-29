import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core_shared/core_shared.dart';
import '../../core/theme.dart';
import '../../data/repositories/admin_repository.dart';
import '../../logic/cubits/users/users_cubit.dart';
import '../../logic/cubits/users/users_state.dart';
import '../widgets/base_table_screen.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => UsersCubit(adminRepository: adminRepository)..fetchUsers(),
      child: const _UsersScreenContent(),
    );
  }
}

class _UsersScreenContent extends StatefulWidget {
  const _UsersScreenContent();

  @override
  State<_UsersScreenContent> createState() => _UsersScreenContentState();
}

class _UsersScreenContentState extends State<_UsersScreenContent> {
  void _showUserDetailDialog(UserModel user) {
    final profile = user.profile;
    final metrics = user.metrics;
    final goal = user.goal;

    final isAssessmentDone = profile?.isAssessmentCompleted ?? false;
    final genderStr = profile?.gender ?? 'Chưa cập nhật';
    final ageStr = metrics?.age != null ? '${metrics!.age} tuổi' : 'Chưa cập nhật';
    final heightStr = metrics?.heightCm != null ? '${metrics!.heightCm} cm' : 'Chưa cập nhật';
    final weightStr = metrics?.weight != null ? '${metrics!.weight} kg' : 'Chưa cập nhật';
    final targetWeightStr = goal?.targetWeight != null ? '${goal!.targetWeight} kg' : 'Chưa đặt';
    final goalTypeStr = goal?.type ?? metrics?.goal ?? 'Chưa đặt';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: 650,
          constraints: const BoxConstraints(maxHeight: 800),
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppTheme.primaryLight,
                    child: Text(
                      (profile?.fullName ?? user.email)[0].toUpperCase(),
                      style: const TextStyle(fontSize: 20, color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile?.fullName ?? 'Chưa cập nhật tên',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(user.email, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 28, color: Color(0xFFF1F5F9)),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section 1: Survey Status & Role
                      const Text('Trạng thái & Quyền hạn', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isAssessmentDone ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isAssessmentDone ? const Color(0xFFA7F3D0) : const Color(0xFFFCA5A5)),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isAssessmentDone ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
                                    color: isAssessmentDone ? const Color(0xFF10B981) : Colors.red,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Khảo sát đầu vào', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                        Text(
                                          isAssessmentDone ? 'Đã hoàn thành' : 'Chưa thực hiện',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: isAssessmentDone ? const Color(0xFF10B981) : Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.admin_panel_settings_rounded, color: AppTheme.primaryColor, size: 20),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Vai trò hệ thống', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                      Text(
                                        user.role,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Section 2: Physical Metrics
                      const Text('Chỉ số Thể hình & Nhân trắc học', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            _buildDetailRow('Giới tính', genderStr),
                            _buildDetailRow('Tuổi', ageStr),
                            _buildDetailRow('Chiều cao', heightStr),
                            _buildDetailRow('Cân nặng hiện tại', weightStr),
                            if (metrics?.bmi != null) _buildDetailRow('Chỉ số BMI', metrics!.bmi!.toStringAsFixed(1)),
                            if (metrics?.bmr != null) _buildDetailRow('Chỉ số BMR', '${metrics!.bmr!.toStringAsFixed(0)} kcal'),
                            if (metrics?.tdee != null) _buildDetailRow('Chỉ số TDEE', '${metrics!.tdee!.toStringAsFixed(0)} kcal'),
                            if (metrics?.targetCalories != null) _buildDetailRow('Calo mục tiêu/ngày', '${metrics!.targetCalories!.toStringAsFixed(0)} kcal'),
                            if (metrics?.activityLevel != null) _buildDetailRow('Mức độ vận động', metrics!.activityLevel!),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Section 3: Personal Goals
                      const Text('Mục tiêu Sức khỏe & Tập luyện', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            _buildDetailRow('Loại mục tiêu', goalTypeStr),
                            _buildDetailRow('Cân nặng mục tiêu', targetWeightStr),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Đóng', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UsersCubit, UsersState>(
      builder: (context, state) {
        final isLoading = state is UsersLoading;
        final users = state is UsersSuccess ? state.users : <UserModel>[];

        return BaseTableScreen(
          title: 'Quản lý Người dùng',
          subtitle: 'Danh sách tất cả tài khoản người dùng trong hệ thống',
          searchHint: 'Tìm kiếm tên, email...',
          onSearchChanged: (query) => context.read<UsersCubit>().fetchUsers(search: query),
          onRefresh: () => context.read<UsersCubit>().fetchUsers(forceRefresh: true),
          columns: const [
            'Tài khoản / Email',
            'Họ & Tên',
            'Ngày tạo',
            'Vai trò',
            'Hành động',
          ],
          isLoading: isLoading,
          totalElements: users.length,
              rows: users.map((user) {
                final roleStr = user.role;
                final isAdmin = roleStr == 'ADMIN';
                final dateStr = user.createdAt != null
                    ? '${user.createdAt!.day.toString().padLeft(2, '0')}/${user.createdAt!.month.toString().padLeft(2, '0')}/${user.createdAt!.year}'
                    : '---';
                return DataRow(
                  cells: [
                    DataCell(
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: AppTheme.primaryLight,
                            child: Text(
                              (user.profile?.fullName ?? user.email)[0].toUpperCase(),
                              style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(user.email, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        ],
                      ),
                    ),
                    DataCell(Text(user.profile?.fullName ?? '---', style: const TextStyle(fontSize: 14))),
                    DataCell(Text(dateStr, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary))),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: isAdmin ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          roleStr,
                          style: TextStyle(
                            color: isAdmin ? const Color(0xFF3B82F6) : AppTheme.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      IconButton(
                        icon: const Icon(Icons.visibility_outlined, size: 20, color: AppTheme.textSecondary),
                        onPressed: () => _showUserDetailDialog(user),
                        tooltip: 'Xem chi tiết',
                      ),
                    ),
                  ],
                );
              }).toList(),
        );
      },
    );
  }
}
