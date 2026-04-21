import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/presentation/bloc/user/user_cubit.dart';
import 'package:mobile/presentation/bloc/user/user_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Fitness Metrics', onSeeAll: () {}),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 180,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildMetricCard(
                          title: 'Score',
                          value: '88',
                          unit: '%',
                          icon: Icons.add,
                          color: const Color(0xFFF97316),
                          chartType: 'bar',
                        ),
                        const SizedBox(width: 16),
                        _buildMetricCard(
                          title: 'Hydration',
                          value: '781',
                          unit: 'ml',
                          icon: Icons.water_drop,
                          color: const Color(0xFF3B82F6),
                          chartType: 'line',
                        ),
                        const SizedBox(width: 16),
                        _buildMetricCard(
                          title: 'Calories',
                          value: '1,240',
                          unit: 'kcal',
                          icon: Icons.local_fire_department,
                          color: const Color(0xFF64748B),
                          chartType: 'dots',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildSectionHeader('Workouts', onSeeAll: () {}),
                  const SizedBox(height: 16),
                  _buildWorkoutCard(),
                  const SizedBox(height: 32),
                  _buildSectionHeader('Diet & Nutrition', onSeeAll: () {}),
                  const SizedBox(height: 16),
                  _buildDietCard(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDietCard() {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        image: const DecorationImage(image: AssetImage('assets/images/fruit.png'), fit: BoxFit.cover),
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildIconLabel(Icons.restaurant_menu_outlined, 'Lunch'),
                    const SizedBox(width: 12),
                    _buildIconLabel(Icons.local_fire_department_outlined, '540kcal'),
                  ],
                ),
                const Spacer(),
                const Text(
                  'Mediterranean Salad',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('High Protein • Fresh', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(12)),
                      child: const Text(
                        'View Recipe',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    required String chartType,
  }) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              Icon(icon, color: Colors.white, size: 20),
            ],
          ),
          const Spacer(),
          _buildMiniChart(chartType),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 2),
              Text(
                unit,
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniChart(String type) {
    if (type == 'bar') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(5, (index) {
          final heights = [10.0, 25.0, 40.0, 30.0, 15.0];
          return Container(
            width: 8,
            height: heights[index],
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3 + (index * 0.1)),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      );
    } else if (type == 'line') {
      return Icon(Icons.show_chart, color: Colors.white.withOpacity(0.5), size: 50);
    } else {
      return Column(
        children: List.generate(
          4,
          (index) => Container(
            margin: const EdgeInsets.only(bottom: 4),
            width: 20,
            height: 6,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(3)),
          ),
        ),
      );
    }
  }

  Widget _buildWorkoutCard() {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        image: const DecorationImage(image: AssetImage('assets/images/gym_workout.png'), fit: BoxFit.cover),
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildIconLabel(Icons.timer_outlined, '25min'),
                    const SizedBox(width: 12),
                    _buildIconLabel(Icons.local_fire_department_outlined, '412kcal'),
                  ],
                ),
                const Spacer(),
                const Text(
                  'Upper Strength 2',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('8 Series Workout', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: const Text('Intense', style: TextStyle(color: Colors.white, fontSize: 10)),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                      child: const Icon(Icons.play_arrow, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconLabel(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.7), size: 16),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;

    final today = DateFormat('MMM dd, yyyy').format(DateTime.now()).toUpperCase();

    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: AppTheme.darkBackground,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
          ),
          child: Stack(
            children: [
              // Abstract background decorative circles
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), shape: BoxShape.circle),
                ),
              ),

              Padding(
                padding: EdgeInsets.fromLTRB(24, statusBarHeight + 10, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.calendar_today, color: Colors.white.withOpacity(0.6), size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  today,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        _buildNotificationIcon(),
                      ],
                    ),
                    const Spacer(),
                    BlocBuilder<UserCubit, UserState>(
                      builder: (context, state) {
                        String name = 'Guest';
                        String? avatarUrl;
                        bool isLoading = state is UserLoading;

                        if (state is UserLoaded) {
                          name = state.user.profile?.fullName ?? 'Member';
                          print(name);
                          avatarUrl = state.user.profile?.avatarUrl;
                        }

                        return Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(50),
                                child: isLoading
                                    ? Container(width: 100, height: 100, color: Colors.white10)
                                    : (avatarUrl != null && avatarUrl.isNotEmpty)
                                    ? Image.network(
                                        avatarUrl,
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Image.asset(
                                          'assets/images/man.png',
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Image.asset('assets/images/man.png', width: 100, height: 100, fit: BoxFit.cover),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isLoading ? 'Loading...' : 'Hello, $name!',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      _buildStatusBadge(
                                        icon: Icons.add_circle,
                                        label: '88% Healthy',
                                        color: AppTheme.primary,
                                      ),
                                      const SizedBox(width: 12),
                                      _buildStatusBadge(icon: Icons.star, label: 'Pro', color: Colors.blueAccent),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.5)),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon() {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.notifications, color: Colors.white, size: 22),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
            child: const Text(
              '8',
              style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge({required IconData icon, required String label, required Color color}) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, {required VoidCallback onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
        TextButton(
          onPressed: onSeeAll,
          child: const Text(
            'See All',
            style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
