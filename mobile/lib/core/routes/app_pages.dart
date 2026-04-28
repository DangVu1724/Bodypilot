import 'package:flutter/material.dart';
import 'package:mobile/core/routes/app_routes.dart';
import 'package:mobile/presentation/screens/assessment/assessment_screen.dart';
import 'package:mobile/presentation/screens/auth/login_screen.dart';
import 'package:mobile/presentation/screens/auth/signup_screen.dart';
import 'package:mobile/presentation/screens/home/home_screen.dart';
import 'package:mobile/presentation/screens/main/main_screen.dart';
import 'package:mobile/presentation/screens/food/food_detail_screen.dart';
import 'package:mobile/presentation/screens/food/ingredient_detail_screen.dart';
import 'package:mobile/presentation/screens/food/food_list_screen.dart';

import 'package:mobile/presentation/screens/welcome/onboarding_screen.dart';
import 'package:mobile/presentation/screens/welcome/splash_screen.dart';
import 'package:mobile/presentation/screens/welcome/welcome_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/presentation/bloc/food_list/food_list_cubit.dart';
import 'package:mobile/data/repositories/food_repository.dart';

class AppPages {
  AppPages._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return _buildRoute(const SplashScreen(), settings);
      case AppRoutes.onboarding:
        return _buildRoute(const OnboardingScreen(), settings);
      case AppRoutes.welcome:
        return _buildRoute(const WelcomeScreen(), settings);
      case AppRoutes.login:
        return _buildRoute(const LoginScreen(), settings);
      case AppRoutes.signup:
        return _buildRoute(const SignUpScreen(), settings);
      case AppRoutes.assessment:
        return _buildRoute(const AssessmentScreen(), settings);
      case AppRoutes.home:
        return _buildRoute(const MainScreen(), settings);
      case AppRoutes.foodDetail:
        final foodId = settings.arguments as String;
        return _buildRoute(FoodDetailScreen(foodId: foodId), settings);
      case AppRoutes.ingredientDetail:
        final foodId = settings.arguments as String;
        return _buildRoute(IngredientDetailScreen(foodId: foodId), settings);
      case AppRoutes.foodList:
        final type = settings.arguments as String;
        return _buildRoute(
          BlocProvider(
            create: (context) => FoodListCubit(foodRepository),
            child: FoodListScreen(type: type),
          ),
          settings,
        );
      default:
        return _buildRoute(const SplashScreen(), settings);
    }
  }

  static PageRoute<dynamic> _buildRoute(Widget child, RouteSettings settings) {
    return MaterialPageRoute<dynamic>(builder: (_) => child, settings: settings);
  }
}
