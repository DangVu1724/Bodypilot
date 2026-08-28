import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/presentation/bloc/step/step_cubit.dart';
import 'package:mobile/presentation/bloc/user/user_cubit.dart';
import 'package:mobile/presentation/bloc/user/user_state.dart';
import 'package:mobile/presentation/screens/meal/widgets/dashboard/calorie_dashboard_card.dart';
import 'package:mobile/presentation/screens/meal/widgets/dashboard/weight_goal_card.dart';
import 'package:mobile/presentation/screens/meal/widgets/sections/browse_meals_list.dart';
import 'package:mobile/presentation/screens/meal/widgets/sections/meal_plan_section.dart';
import 'package:mobile/presentation/screens/workout/widgets/ai_suggestion/ai_suggestion_banner.dart';
import 'package:mobile/presentation/widgets/hero_profile_avatar.dart';

class MealScreen extends StatefulWidget {
  const MealScreen({super.key});

  @override
  State<MealScreen> createState() => _MealScreenState();
}

class _MealScreenState extends State<MealScreen> {
  int _calculateTargetSteps(String goal, String? gender) {
    final isFemale = gender?.toUpperCase() == 'FEMALE' || gender == 'Nữ';
    final isMale = gender?.toUpperCase() == 'MALE' || gender == 'Nam';

    switch (goal) {
      case 'LOSE_1KG':
        if (isFemale) return 12000;
        if (isMale) return 15000;
        return 13500;
      case 'LOSE_0_5KG':
        if (isFemale) return 10000;
        if (isMale) return 12500;
        return 11000;
      case 'HEALTHY_LIFESTYLE':
        if (isFemale) return 8000;
        if (isMale) return 10000;
        return 9000;
      case 'MAINTAIN':
        if (isFemale) return 7000;
        if (isMale) return 8000;
        return 7500;
      case 'GAIN_MUSCLE':
        if (isFemale) return 5000;
        if (isMale) return 6000;
        return 5500;
      case 'GAIN_0_5KG':
        if (isFemale) return 4500;
        if (isMale) return 5000;
        return 4500;
      case 'GAIN_1KG':
        return 4000;
      default:
        if (isFemale) return 7000;
        if (isMale) return 8000;
        return 8000;
    }
  }

  String _getStepsAmount(String goal, String? gender) {
    final target = _calculateTargetSteps(goal, gender);
    return NumberFormat('#,###').format(target);
  }

  String _getWaterAmount(double weight) {
    if (weight <= 0) return '0';
    final waterInMl = weight * 0.03 * 1000;
    return '${waterInMl.round()}';
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final stepState = context.watch<StepCubit>().state;

    return Scaffold(
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
            double weight = 0.0;
            String goal = 'MAINTAIN';
            String? gender;
            String? avatarUrl;

            if (state is UserLoaded) {
              weight = state.user.metrics?.weight ?? 0.0;
              goal = state.user.metrics?.goal ?? 'MAINTAIN';
              gender = state.user.profile?.gender;
              avatarUrl = state.user.profile?.avatarUrl;
            }

            String targetStepsStr = _getStepsAmount(goal, gender);
            String currentStepsStr = NumberFormat('#,###').format(stepState.steps);
            String stepsDisplay = '$currentStepsStr / $targetStepsStr';
            String waterStr = _getWaterAmount(weight);

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
                                  'Hàng Ngày',
                                  style: AppTheme.bodyStyle.copyWith(
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Kế Hoạch Dinh Dưỡng',
                                  style: AppTheme.headlineStyle.copyWith(color: const Color(0xFF1E293B), fontSize: 20),
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
                      children: [
                        CalorieDashboardCard(),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                title: 'Bước chân',
                                value: stepsDisplay,
                                unit: 'bước',
                                icon: FontAwesomeIcons.shoePrints,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                title: 'Nước uống',
                                value: waterStr,
                                unit: 'ml',
                                icon: FontAwesomeIcons.glassWater,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        const WeightGoalCard(),
                        const SizedBox(height: 32),
                        const MealPlanSection(),
                        const SizedBox(height: 32),
                        const AiSuggestionBanner(),
                        const SizedBox(height: 32),
                        const BrowseMealsList(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String unit,
    required FaIconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTheme.semiboldStyle.copyWith(fontSize: 14, color: const Color(0xFF3F2B1A)),
                ),
              ),
              FaIcon(icon, size: 18, color: AppTheme.primary),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: AppTheme.headlineStyle.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF3F2B1A),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 2.0),
                child: Text(unit, style: AppTheme.bodyStyle.copyWith(fontSize: 12, color: Colors.grey.shade600)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
