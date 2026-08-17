import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'presentation/widgets/sidebar.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/dashboard_screen.dart';
import 'presentation/screens/users_screen.dart';
import 'presentation/screens/exercises_screen.dart';
import 'presentation/screens/dishes_screen.dart';
import 'presentation/screens/ingredients_screen.dart';

void main() {
  runApp(const AdminApp());
}

class AdminApp extends StatefulWidget {
  const AdminApp({super.key});

  @override
  State<AdminApp> createState() => _AdminAppState();
}

class _AdminAppState extends State<AdminApp> {
  bool _isLoggedIn = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BodyPilot Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: _isLoggedIn
          ? MainLayout(
              onLogout: () {
                setState(() {
                  _isLoggedIn = false;
                });
              },
            )
          : LoginScreen(
              onLoginSuccess: () {
                setState(() {
                  _isLoggedIn = true;
                });
              },
            ),
    );
  }
}

class MainLayout extends StatefulWidget {
  final VoidCallback onLogout;

  const MainLayout({super.key, required this.onLogout});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  final Set<int> _loadedIndices = {0}; // Chỉ nạp Dashboard (index 0) lúc vừa đăng nhập

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          AdminSidebar(
            selectedIndex: _selectedIndex,
            onItemSelected: (index) {
              setState(() {
                _selectedIndex = index;
                _loadedIndices.add(index); // Nạp dữ liệu màn hình khi người dùng bấm vào tab
              });
            },
          ),
          const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFE2E8F0)),
          Expanded(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: [
                      _loadedIndices.contains(0) ? const DashboardScreen() : const SizedBox.shrink(),
                      _loadedIndices.contains(1) ? const UsersScreen() : const SizedBox.shrink(),
                      _loadedIndices.contains(2) ? const ExercisesScreen() : const SizedBox.shrink(),
                      _loadedIndices.contains(3) ? const DishesScreen() : const SizedBox.shrink(),
                      _loadedIndices.contains(4) ? const IngredientsScreen() : const SizedBox.shrink(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          // Left Page Info / Breadcrumb
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                'Xin chào Admin, chúc bạn một ngày làm việc hiệu quả!',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const Spacer(),

          // Search Box (Reztro Style)
          Container(
            width: 320,
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFEBECEF)),
            ),
            child: const Row(
              children: [
                Icon(Icons.search_rounded, color: AppTheme.textSecondary, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tìm kiếm dữ liệu...',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),

          // Notification Bell Button
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFEBECEF)),
                ),
                child: IconButton(
                  icon: const Icon(Icons.notifications_none_rounded, color: AppTheme.textPrimary, size: 20),
                  onPressed: () {},
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
              ),
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // Settings Button
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFEBECEF)),
            ),
            child: IconButton(
              icon: const Icon(Icons.settings_outlined, color: AppTheme.textPrimary, size: 20),
              onPressed: () {},
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
          ),
          const SizedBox(width: 16),
          const SizedBox(height: 24, child: VerticalDivider(width: 1, color: AppTheme.borderColor)),
          const SizedBox(width: 16),

          // Admin User Profile Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: const Color(0xFFEBECEF)),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.primaryColor,
                  child: Text(
                    'A',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 10),
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin BodyPilot',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                    ),
                    Text(
                      'System Admin',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 18),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Xác nhận đăng xuất'),
                        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi hệ thống admin?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Hủy'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              Navigator.pop(ctx);
                              widget.onLogout();
                            },
                            child: const Text('Đăng xuất'),
                          ),
                        ],
                      ),
                    );
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
