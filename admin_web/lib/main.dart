import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'presentation/screens/dashboard_screen.dart';
import 'presentation/screens/dishes_screen.dart';
import 'presentation/screens/exercises_screen.dart';
import 'presentation/screens/ingredients_screen.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/users_screen.dart';
import 'presentation/widgets/sidebar.dart';

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
            onLogout: widget.onLogout,
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
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),
          const Spacer(),

          // Clean Admin User Profile Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: const Color(0xFFEBECEF)),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.primaryColor,
                  backgroundImage: AssetImage('assets/images/logo.png'),
                ),
                SizedBox(width: 10),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin BodyPilot',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                    ),
                    Text('System Admin', style: TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
