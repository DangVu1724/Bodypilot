import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/presentation/bloc/user/user_cubit.dart';
import 'package:mobile/presentation/bloc/user/user_state.dart';
import 'package:mobile/presentation/widgets/hero_profile_avatar.dart';
import '../../bloc/workout/exercise_cubit.dart';
import '../../bloc/workout/workout_category_cubit.dart';
import '../../../data/repositories/exercise_repository.dart';
import 'widgets/category_chips.dart';
import 'widgets/ai_suggestion_banner.dart';
import 'widgets/featured_card.dart';
import 'widgets/strength_section.dart';
import 'widgets/ai_suggestion_card.dart';

class WorkoutScreen extends StatelessWidget {
  const WorkoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final exerciseRepository = ExerciseRepository();
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => ExerciseCubit(exerciseRepository)..fetchStrengthExercises()),
        BlocProvider(create: (context) => WorkoutCategoryCubit(exerciseRepository)..fetchCategories()),
      ],
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFA0AEC0), // Slate Grey
                Color(0xFFD6CCC2), // Warm Beige
              ],
            ),
          ),
          child: BlocBuilder<UserCubit, UserState>(
            builder: (context, state) {
              String? userName;
              String? avatarUrl;

              if (state is UserLoaded) {
                userName = state.user.profile?.fullName;
                avatarUrl = state.user.profile?.avatarUrl;
              }

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    expandedHeight: 120,
                    pinned: true,
                    stretch: true,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    flexibleSpace: FlexibleSpaceBar(
                      stretchModes: const [StretchMode.zoomBackground],
                      background: Container(
                        color: Colors.transparent,
                        padding: EdgeInsets.fromLTRB(24, statusBarHeight + 10, 24, 10),
                        child: Row(
                          children: [
                            HeroProfileAvatar(
                              avatarUrl: avatarUrl,
                              radius: 22,
                              heroTag: 'profile_avatar',
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Body Pilot',
                                    style: AppTheme.bodyStyle.copyWith(
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Training Center',
                                    style: AppTheme.headlineStyle.copyWith(
                                      color: const Color(0xFF1E293B),
                                      fontSize: 20,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          CategoryChips(),
                          SizedBox(height: 16),
                          AiSuggestionBanner(),
                          SizedBox(height: 24),
                          FeaturedCard(),
                          SizedBox(height: 24),
                          StrengthSection(),
                          SizedBox(height: 24),
                          AiSuggestionCard(),
                          SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
