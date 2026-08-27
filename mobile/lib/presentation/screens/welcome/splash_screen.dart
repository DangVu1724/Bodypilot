import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/routes/app_routes.dart';
import 'package:mobile/core/theme/app_theme.dart';
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
          body: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(image: AssetImage('assets/images/logo.png'), fit: BoxFit.cover),
                  ),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.3),
                        const Color(0xFF0F172A).withOpacity(0.85),
                        const Color(0xFF0F172A),
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(flex: 3),
                      Text('BodyPilot', style: AppTheme.headlineStyle.copyWith(fontSize: 40, color: Colors.white)),
                      const SizedBox(height: 8),
                      Text(
                        'Quản lý Dinh dưỡng & Luyện tập Cá nhân hóa',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.85),
                          letterSpacing: 0.2,
                        ),
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
            ],
          ),
        ),
      ),
    );
  }
}
