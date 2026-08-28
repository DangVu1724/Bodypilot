import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/presentation/bloc/user/user_cubit.dart';
import 'package:mobile/presentation/bloc/user/user_state.dart';

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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chào $userName 👋',
                  style: AppTheme.headlineStyle.copyWith(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hãy giữ thói quen tập luyện hôm nay nhé!',
                  style: AppTheme.bodyStyle.copyWith(color: AppTheme.textSecondary),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
