import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/routes/app_routes.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/presentation/bloc/notification/notification_cubit.dart';
import 'package:mobile/presentation/bloc/notification/notification_state.dart';
import 'package:mobile/presentation/bloc/user/user_cubit.dart';
import 'package:mobile/presentation/bloc/user/user_state.dart';
import 'package:mobile/presentation/widgets/hero_profile_avatar.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning!';
    } else if (hour < 17) {
      return 'Good Afternoon!';
    } else {
      return 'Good Evening!';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      stretch: true,
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Container(
          color: Colors.transparent,
          padding: EdgeInsets.fromLTRB(24, statusBarHeight + 10, 24, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      BlocBuilder<UserCubit, UserState>(
                        builder: (context, state) {
                          String? avatarUrl;
                          if (state is UserLoaded) {
                            avatarUrl = state.user.profile?.avatarUrl;
                          }
                          return HeroProfileAvatar(
                            avatarUrl: avatarUrl,
                            radius: 28,
                            heroTag: 'profile_avatar',
                            border: Border.all(color: Colors.white, width: 2),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getGreeting(),
                            style: AppTheme.bodyStyle.copyWith(color: Colors.grey.shade600, fontSize: 13),
                          ),
                          BlocBuilder<UserCubit, UserState>(
                            builder: (context, state) {
                              String name = 'User';
                              if (state is UserLoaded) {
                                name = state.user.profile?.fullName ?? 'User';
                              }
                              return Text(
                                name,
                                style: AppTheme.headlineStyle.copyWith(fontSize: 20, color: const Color(0xFF1E293B)),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  _buildNotificationIcon(context),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildNotificationIcon(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.notifications),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.notifications_rounded, color: Colors.white, size: 22),
          ),
          BlocBuilder<NotificationCubit, NotificationState>(
            builder: (context, state) {
              if (state.unreadCount == 0) return const SizedBox.shrink();
              return Positioned(
                top: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF7A30), // Primary Orange Accent
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF0F172A), width: 1.5),
                  ),
                  child: Text(
                    state.unreadCount > 99 ? '99+' : state.unreadCount.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
