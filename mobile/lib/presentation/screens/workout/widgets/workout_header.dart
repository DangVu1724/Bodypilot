import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../bloc/user/user_cubit.dart';
import '../../../bloc/user/user_state.dart';

class WorkoutHeader extends StatelessWidget {
  const WorkoutHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserCubit, UserState>(
      builder: (context, state) {
        String userName = 'Guest';
        if (state is UserLoaded) {
          userName = state.user.profile?.fullName ?? 'Guest';
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundImage: NetworkImage(
                    'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150&q=80',
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ready for training 🏋️',
                      style: AppTheme.bodyStyle.copyWith(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                    Row(
                      children: [
                        Text(userName, style: AppTheme.headlineStyle.copyWith(fontSize: 20)),
                        const SizedBox(width: 4),
                        const Icon(Icons.verified, color: AppTheme.primary, size: 16),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            Container(
              decoration: BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
              child: IconButton(
                icon: const Icon(Icons.search, color: AppTheme.textPrimary),
                onPressed: () {},
              ),
            ),
          ],
        );
      },
    );
  }
}
