import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/presentation/bloc/user/user_cubit.dart';
import 'package:mobile/presentation/bloc/user/user_state.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
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
                        Row(
                          children: [
                            Icon(Icons.calendar_today, color: Colors.white.withOpacity(0.6), size: 14),
                            const SizedBox(width: 6),
                            Text(
                              today,
                              style: AppTheme.bodyStyle.copyWith(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
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
                                    style: AppTheme.headlineStyle.copyWith(
                                      color: Colors.white,
                                      fontSize: 24,
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
          style: AppTheme.bodyStyle.copyWith(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
