import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/routes/app_routes.dart';
import 'package:mobile/presentation/screens/assessment/assessment_screen.dart';
import 'package:mobile/presentation/screens/auth/login_screen.dart';
import 'package:mobile/presentation/screens/auth/signup_screen.dart';
import 'package:mobile/presentation/screens/main/main_screen.dart';
import 'package:mobile/presentation/screens/meal/meal_plan_screen.dart';
import 'package:mobile/presentation/screens/food/food_detail_screen.dart';
import 'package:mobile/presentation/screens/food/ingredient_detail_screen.dart';
import 'package:mobile/presentation/screens/food/food_list_screen.dart';

import 'package:mobile/presentation/screens/welcome/onboarding_screen.dart';
import 'package:mobile/presentation/screens/welcome/splash_screen.dart';
import 'package:mobile/presentation/screens/welcome/welcome_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/presentation/bloc/food_list/food_list_cubit.dart';
import 'package:mobile/data/repositories/food_repository.dart';
import 'package:mobile/presentation/screens/workout/workout_diary_screen.dart';
import 'package:mobile/presentation/screens/metrics/calorie_balance_detail_screen.dart';
import 'package:mobile/presentation/screens/metrics/protein_detail_screen.dart';
import 'package:mobile/presentation/screens/metrics/active_minutes_detail_screen.dart';
import 'package:mobile/presentation/screens/notification/notification_screen.dart';
import 'package:mobile/presentation/screens/chat/ai_chat_screen.dart';
import 'package:mobile/presentation/bloc/chat/chatbot_cubit.dart';
import 'package:mobile/presentation/screens/step/step_detail_screen.dart';

class AppPages {
  AppPages._();

  static final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (context, state) => const SplashScreen()),
      GoRoute(path: AppRoutes.onboarding, builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: AppRoutes.welcome, builder: (context, state) => const WelcomeScreen()),
      GoRoute(path: AppRoutes.login, builder: (context, state) => const LoginScreen()),
      GoRoute(path: AppRoutes.signup, builder: (context, state) => const SignUpScreen()),
      GoRoute(path: AppRoutes.assessment, builder: (context, state) => const AssessmentScreen()),
      GoRoute(path: AppRoutes.home, builder: (context, state) => const MainScreen()),
      GoRoute(
        path: AppRoutes.mealPlan,
        builder: (context, state) {
          final selectedDate = state.extra as DateTime?;
          return MealPlanScreen(initialDate: selectedDate);
        },
      ),
      GoRoute(
        path: AppRoutes.workoutDiary,
        builder: (context, state) {
          final selectedDate = state.extra as DateTime?;
          return WorkoutDiaryScreen(initialDate: selectedDate);
        },
      ),
      GoRoute(path: AppRoutes.calorieBalanceDetail, builder: (context, state) => const CalorieBalanceDetailScreen()),
      GoRoute(path: AppRoutes.proteinDetail, builder: (context, state) => const ProteinDetailScreen()),
      GoRoute(path: AppRoutes.activeMinutesDetail, builder: (context, state) => const ActiveMinutesDetailScreen()),
      GoRoute(path: AppRoutes.notifications, builder: (context, state) => const NotificationScreen()),
      GoRoute(
        path: AppRoutes.foodDetail,
        builder: (context, state) {
          final foodId = state.extra as String;
          return FoodDetailScreen(foodId: foodId);
        },
      ),
      GoRoute(
        path: AppRoutes.ingredientDetail,
        builder: (context, state) {
          final foodId = state.extra as String;
          return IngredientDetailScreen(foodId: foodId);
        },
      ),
      GoRoute(
        path: AppRoutes.foodList,
        builder: (context, state) {
          final type = state.extra as String;
          return BlocProvider(
            create: (context) => FoodListCubit(foodRepository),
            child: FoodListScreen(type: type),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.aiChat,
        builder: (context, state) => BlocProvider(
          create: (context) => ChatbotCubit(),
          child: const AiChatScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.stepDetail,
        builder: (context, state) => const StepDetailScreen(),
      ),
    ],
  );
}
