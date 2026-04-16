// splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/routes/app_routes.dart';
import 'package:mobile/presentation/bloc/splash/splash_cubit.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SplashCubit()..startSplash(),
      child: BlocListener<SplashCubit, bool>(
        listener: (context, isCompleted) {
          if (isCompleted) {
            Navigator.pushReplacementNamed(context, AppRoutes.welcome);
          }
        },
        child: Scaffold(
          body: Image.asset(
            'assets/images/logo.png',
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
