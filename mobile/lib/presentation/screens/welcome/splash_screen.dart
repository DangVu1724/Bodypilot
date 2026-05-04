// splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/routes/app_routes.dart';
import 'package:mobile/presentation/bloc/splash/splash_cubit.dart';
import 'package:mobile/presentation/bloc/user/user_cubit.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isNavigated = false;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SplashCubit(context.read<UserCubit>())..startSplash(),
      child: BlocListener<SplashCubit, SplashStatus>(
        listener: (context, status) {
          if (_isNavigated) return;

          switch (status) {
            case SplashStatus.authenticated:
              _isNavigated = true;
              Navigator.pushReplacementNamed(context, AppRoutes.home);
              break;
            case SplashStatus.needsAssessment:
              _isNavigated = true;
              Navigator.pushReplacementNamed(context, AppRoutes.assessment);
              break;
            case SplashStatus.unauthenticated:
              _isNavigated = true;
              Navigator.pushReplacementNamed(context, AppRoutes.welcome);
              break;
            case SplashStatus.loading:
            case SplashStatus.error:
            default:
              break;
          }
        },
        child: Scaffold(
          body: Stack(
            children: [
              Image.asset('assets/images/logo.png', width: double.infinity, height: double.infinity, fit: BoxFit.cover),
              // UI for error state removed as internet check is disabled
              const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }
}
