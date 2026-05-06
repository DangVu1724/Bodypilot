import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'presentation/widgets/sidebar.dart';
import 'presentation/screens/dashboard_screen.dart';
import 'presentation/screens/users_screen.dart';
import 'presentation/screens/exercises_screen.dart';
import 'presentation/screens/dishes_screen.dart';
import 'presentation/screens/ingredients_screen.dart';

void main() {
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BodyPilot Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainLayout(),
    );
  }
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

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
                    children: const [
                      DashboardScreen(),
                      UsersScreen(),
                      ExercisesScreen(),
                      DishesScreen(),
                      IngredientsScreen(),
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
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.search, color: AppTheme.textSecondary, size: 20),
                  SizedBox(width: 8),
                  Text('Tìm kiếm thông tin...', style: TextStyle(color: AppTheme.textSecondary)),
                ],
              ),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.notifications_none, color: AppTheme.textSecondary),
            onPressed: () {},
          ),
          const SizedBox(width: 16),
          const VerticalDivider(indent: 20, endIndent: 20),
          const SizedBox(width: 16),
          const CircleAvatar(
            backgroundColor: Color(0xFFE2E8F0),
            child: Icon(Icons.person_outline, color: AppTheme.textSecondary),
          ),
          const SizedBox(width: 12),
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Admin BodyPilot', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text('Quản trị viên', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
