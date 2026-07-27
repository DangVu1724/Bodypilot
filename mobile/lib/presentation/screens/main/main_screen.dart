import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';

import 'package:mobile/presentation/screens/home/home_screen.dart';
import 'package:mobile/presentation/screens/meal/meal_screen.dart';
import 'package:mobile/presentation/screens/workout/workout_screen.dart';
import 'package:mobile/presentation/screens/profile/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const MealScreen(),
    const WorkoutScreen(),
    const ProfileScreen(),
  ];

  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    
    setState(() {
      _selectedIndex = index;
    });

    _navigatorKey.currentState!.pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => _screens[index],
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData selectedIcon, IconData unselectedIcon, String label) {
    final isSelected = _selectedIndex == index;
    final color = isSelected ? AppTheme.primary : const Color(0xFF5A606A);
    
    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? selectedIcon : unselectedIcon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5E5E5),
      body: Navigator(
        key: _navigatorKey,
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (context) => _screens[_selectedIndex],
        ),
      ),
      bottomNavigationBar: Container(
        height: 72,
        decoration: BoxDecoration(
          color: const Color(0xFFD6CCC2).withOpacity(0.95), // Blends with screen's warm beige bottom
          border: Border(
            top: BorderSide(
              color: Colors.black.withOpacity(0.06),
              width: 0.5,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, 'Home'),
              _buildNavItem(1, Icons.restaurant_rounded, Icons.restaurant_outlined, 'Meal'),
              _buildNavItem(2, Icons.fitness_center_rounded, Icons.fitness_center_outlined, 'Workout'),
              _buildNavItem(3, Icons.person_rounded, Icons.person_outline, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
}

