import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/routes/app_routes.dart';
import 'package:go_router/go_router.dart';
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
              context.go(AppRoutes.home);
              break;
            case SplashStatus.needsAssessment:
              _isNavigated = true;
              context.go(AppRoutes.assessment);
              break;
            case SplashStatus.unauthenticated:
              _isNavigated = true;
              context.go(AppRoutes.welcome);
              break;
            case SplashStatus.loading:
            case SplashStatus.error:
            default:
              break;
          }
        },
        child: Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 3),
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFFF97316).withOpacity(0.2), blurRadius: 30, spreadRadius: 2),
                        ],
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'BodyPilot',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Trợ lý Sức khỏe & Dinh dưỡng AI',
                      style: GoogleFonts.plusJakartaSans(fontSize: 15, color: Colors.white70, letterSpacing: 0.2),
                    ),
                    const Spacer(flex: 2),
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF97316)),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
