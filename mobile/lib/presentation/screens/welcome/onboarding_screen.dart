import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/routes/app_routes.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/presentation/bloc/onboarding/onboarding_cubit.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OnboardingCubit(),
      child: BlocListener<OnboardingCubit, int>(
        listener: (context, state) {
          if (_pageController.hasClients) {
            final currentPage = _pageController.page?.round() ?? 0;
            if (currentPage != state) {
              _pageController.animateToPage(
                state,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          }
        },
        child: BlocBuilder<OnboardingCubit, int>(
          builder: (context, currentPage) {
            final cubit = context.read<OnboardingCubit>();
            return Scaffold(
              body: Stack(
                children: [
                  Positioned.fill(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: OnboardingCubit.pages.length,
                      onPageChanged: (index) {
                        cubit.goToPage(index);
                      },
                      itemBuilder: (context, index) {
                        final page = OnboardingCubit.pages[index];
                        return Container(
                          width: double.infinity,
                          height: double.infinity,
                          color: const Color(0xFF0F172A),
                          child: Image.asset(page.image, fit: BoxFit.cover),
                        );
                      },
                    ),
                  ),

                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.2),
                              const Color(0xFF0F172A).withOpacity(0.8),
                              const Color(0xFF0F172A),
                            ],
                            stops: const [0.0, 0.55, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),

                  SafeArea(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          child: Align(
                            alignment: Alignment.topRight,
                            child: TextButton(
                              onPressed: () {
                                context.go(AppRoutes.login);
                              },
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.black.withOpacity(0.4),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              child: Text(
                                'Bỏ qua',
                                style: AppTheme.headlineStyle.copyWith(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const Spacer(),

                        Padding(
                          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 30),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(32),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(32),
                                  border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: List.generate(OnboardingCubit.pages.length, (index) {
                                        final isSelected = currentPage == index;
                                        return AnimatedContainer(
                                          duration: const Duration(milliseconds: 250),
                                          margin: const EdgeInsets.symmetric(horizontal: 4),
                                          height: 8,
                                          width: isSelected ? 24 : 8,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(4),
                                            color: isSelected ? const Color(0xFFF97316) : Colors.white.withOpacity(0.3),
                                          ),
                                        );
                                      }),
                                    ),
                                    const SizedBox(height: 24),

                                    ConstrainedBox(
                                      constraints: const BoxConstraints(minHeight: 110),
                                      child: AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 300),
                                        child: Column(
                                          key: ValueKey<int>(currentPage),
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              OnboardingCubit.pages[currentPage].title,
                                              style: AppTheme.headlineStyle.copyWith(
                                                fontSize: 22,
                                                color: Colors.white,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              OnboardingCubit.pages[currentPage].description,
                                              style: GoogleFonts.inter(
                                                fontSize: 14.5,
                                                color: Colors.white.withOpacity(0.85),
                                                height: 1.4,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    if (currentPage == OnboardingCubit.pages.length - 1) ...[
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            context.go(AppRoutes.login);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFFF97316),
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                            padding: const EdgeInsets.symmetric(vertical: 18),
                                            elevation: 4,
                                          ),
                                          child: Text(
                                            'Bắt đầu ngay',
                                            style: AppTheme.headlineStyle.copyWith(
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
