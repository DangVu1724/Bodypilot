import 'package:flutter/material.dart';
import 'package:core_shared/core_shared.dart';
import '../../core/theme.dart';
import '../../data/repositories/admin_repository.dart';
import '../widgets/base_table_screen.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  late Future<List<UserModel>> _usersFuture;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _usersFuture = adminRepository.getAllUsers();
  }

  void _refreshUsers() {
    setState(() {
      _usersFuture = adminRepository.getAllUsers(search: _searchQuery, forceRefresh: true);
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _usersFuture = adminRepository.getAllUsers(search: query, forceRefresh: false);
    });
  }

  void _showUserDetailDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
              child: const Icon(Icons.person, color: AppTheme.primaryColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.profile?.fullName ?? 'Chưa cập nhật tên', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(user.email, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const Text('Chỉ số thể trạng & Mục tiêu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildMetricTile('Cân nặng', '${user.metrics?.weight ?? "N/A"} kg')),
                    Expanded(child: _buildMetricTile('Chiều cao', '${user.metrics?.heightCm ?? "N/A"} cm')),
                    Expanded(child: _buildMetricTile('Tuổi', '${user.metrics?.age ?? "N/A"}')),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildMetricTile('BMI', user.metrics?.bmi?.toStringAsFixed(1) ?? 'N/A')),
                    Expanded(child: _buildMetricTile('BMR', '${user.metrics?.bmr?.toInt() ?? "N/A"} kcal')),
                    Expanded(child: _buildMetricTile('TDEE', '${user.metrics?.tdee?.toInt() ?? "N/A"} kcal')),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const Text('Hảo hán & Trạng thái', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Mục tiêu Fitness'),
                  subtitle: Text(user.goal?.type ?? 'Chưa thiết lập'),
                  trailing: Text('Mục tiêu: ${user.goal?.targetWeight ?? "N/A"} kg', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Mức độ hoạt động'),
                  subtitle: Text(user.metrics?.activityLevel ?? 'Chưa xác định'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Khảo sát ban đầu'),
                  subtitle: Text((user.profile?.isAssessmentCompleted ?? false) ? 'Đã hoàn thành' : 'Chưa khảo sát'),
                  trailing: Icon(
                    (user.profile?.isAssessmentCompleted ?? false) ? Icons.check_circle : Icons.warning,
                    color: (user.profile?.isAssessmentCompleted ?? false) ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<UserModel>>(
      future: _usersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }

        final users = snapshot.data ?? [];

        return BaseTableScreen(
          title: 'Người dùng',
          subtitle: 'Quản lý danh sách người dùng thực tế từ hệ thống',
          onRefresh: _refreshUsers,
          onSearchChanged: _onSearchChanged,
          searchHint: 'Tìm theo tên hoặc email...',
          columns: const ['ID', 'Họ tên', 'Email', 'Trạng thái', 'Thao tác'],
          rows: users.map((user) => DataRow(cells: [
            DataCell(Text(user.id.length >= 8 ? user.id.substring(0, 8) : user.id)),
            DataCell(Text(user.profile?.fullName ?? 'Chưa cập nhật')),
            DataCell(Text(user.email)),
            DataCell(Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (user.profile?.isAssessmentCompleted ?? false)
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                (user.profile?.isAssessmentCompleted ?? false) ? 'Đã khảo sát' : 'Chưa khảo sát',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: (user.profile?.isAssessmentCompleted ?? false) ? Colors.green : Colors.orange,
                ),
              ),
            )),
            DataCell(Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility_outlined, size: 18, color: AppTheme.primaryColor),
                  tooltip: 'Xem chi tiết',
                  onPressed: () => _showUserDetailDialog(user),
                ),
              ],
            )),
          ])).toList(),
        );
      },
    );
  }
}
