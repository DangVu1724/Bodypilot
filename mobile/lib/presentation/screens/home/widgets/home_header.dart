import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/theme/app_theme.dart';
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
                  _buildNotificationIcon(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget buildDateSelector() {
    final days = ['14\nMon', '15\nTue', '16\nWed', '17\nThu', '18\nFri', '19\nSat', '20\nSun'];
    return SizedBox(
      height: 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        itemBuilder: (context, index) {
          bool isSelected = index == 3;
          String date = days[index].split('\n')[0];
          String day = days[index].split('\n')[1];
          return Container(
            width: 50,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(25),
              border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  date,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isSelected ? Colors.black : Colors.grey.shade700,
                  ),
                ),
                Text(
                  day,
                  style: TextStyle(fontSize: 10, color: isSelected ? Colors.grey.shade600 : Colors.grey.shade500),
                ),
                if (isSelected)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 12,
                    height: 3,
                    decoration: BoxDecoration(color: const Color(0xFF84CC16), borderRadius: BorderRadius.circular(2)),
                  ),
              ],
            ),
          );
        },
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
