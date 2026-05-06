import 'package:flutter/material.dart';
import 'package:core_shared/core_shared.dart';
import '../../data/repositories/admin_repository.dart';
import '../widgets/base_table_screen.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  late Future<List<UserModel>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _usersFuture = adminRepository.getAllUsers();
  }

  void _refreshUsers() {
    setState(() {
      _usersFuture = adminRepository.getAllUsers(forceRefresh: true);
    });
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
          columns: const ['ID', 'Họ tên', 'Email', 'Trạng thái', 'Thao tác'],
          rows: users.map((user) => DataRow(cells: [
            DataCell(Text(user.id.substring(0, 8))), // Hiển thị ID ngắn gọn
            DataCell(Text(user.profile?.fullName ?? 'N/A')),
            DataCell(Text(user.email)),
            DataCell(Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (user.profile?.isAssessmentCompleted ?? false) ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
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
                IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () {}),
                IconButton(icon: const Icon(Icons.delete, size: 18, color: Colors.red), onPressed: () {}),
              ],
            )),
          ])).toList(),
        );
      },
    );
  }
}
