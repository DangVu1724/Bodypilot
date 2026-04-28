import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/presentation/bloc/user/user_cubit.dart';
import 'package:mobile/presentation/bloc/user/user_state.dart';
import 'widgets/calorie_dashboard_card.dart';
import 'widgets/weight_goal_card.dart';
import 'widgets/ai_suggestion_banner.dart';
import 'widgets/browse_meals_list.dart';

class MealScreen extends StatefulWidget {
  const MealScreen({super.key});

  @override
  State<MealScreen> createState() => _MealScreenState();
}

class _MealScreenState extends State<MealScreen> {
  String _getStepsAmount(String goal) {
    switch (goal) {
      case 'LOSE_1KG': return '15,000';
      case 'LOSE_0_5KG': return '12,000';
      case 'HEALTHY_LIFESTYLE': return '10,000';
      case 'MAINTAIN': return '8,000';
      case 'GAIN_MUSCLE': return '6,000';
      case 'GAIN_0_5KG': return '5,000';
      case 'GAIN_1KG': return '4,000';
      default: return '8,000';
    }
  }

  String _getWaterAmount(String goal, double weight) {
    if (weight <= 0) return '0';
    switch (goal) {
      case 'LOSE_1KG':
      case 'GAIN_MUSCLE':
        return '${(weight * 45).round()}';
      case 'LOSE_0_5KG':
        return '${(weight * 40).round()}';
      case 'HEALTHY_LIFESTYLE':
      case 'MAINTAIN':
        return '${(weight * 35).round()}';
      case 'GAIN_0_5KG':
        return '${(weight * 35).round()}';
      case 'GAIN_1KG':
        return '${(weight * 30).round()}';
      default:
        return '${(weight * 35).round()}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Meals', style: AppTheme.headlineStyle.copyWith(fontSize: 22)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: BlocBuilder<UserCubit, UserState>(
            builder: (context, state) {
              double weight = 0.0;
              String goal = 'MAINTAIN';

              if (state is UserLoaded) {
                weight = state.user.metrics?.weight ?? 0.0;
                goal = state.user.metrics?.goal ?? 'MAINTAIN';
              }

              String stepsStr = _getStepsAmount(goal);
              String waterStr = _getWaterAmount(goal, weight);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CalorieDashboardCard(),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: 'Steps',
                          value: stepsStr,
                          unit: 'steps',
                          icon: FontAwesomeIcons.shoePrints,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Water',
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
                  const AiSuggestionBanner(),
                  const SizedBox(height: 32),
                  const BrowseMealsList(),
                  const SizedBox(height: 32),
                ],
              );
            },
          ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
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
                child: Text(
                  unit,
                  style: AppTheme.bodyStyle.copyWith(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
