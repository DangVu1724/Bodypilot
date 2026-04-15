import 'package:flutter/material.dart';
import 'package:mobile/core/routes/app_routes.dart';

import 'package:mobile/presentation/screens/welcome/onboarding_screen.dart';
import 'package:mobile/presentation/screens/welcome/splash_screen.dart';
import 'package:mobile/presentation/screens/welcome/welcome_screen.dart';

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
      // case AppRoutes.login:
      //   return _buildRoute(const LoginScreen(), settings);
      // case AppRoutes.home:
      //   return _buildRoute(const HomeScreen(), settings);
      default:
        return _buildRoute(const SplashScreen(), settings);
    }
  }

  static PageRoute<dynamic> _buildRoute(Widget child, RouteSettings settings) {
    return MaterialPageRoute<dynamic>(builder: (_) => child, settings: settings);
  }
}
