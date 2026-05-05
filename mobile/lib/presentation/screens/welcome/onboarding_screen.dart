import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/routes/app_routes.dart';
import 'package:mobile/core/theme/app_theme.dart';
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
          _pageController.animateToPage(state, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        },
        child: BlocBuilder<OnboardingCubit, int>(
          builder: (context, currentPage) {
            return Scaffold(
              body: Stack(
                children: [
                  // Background Image thay đổi theo currentPage
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(OnboardingCubit.pages[currentPage].image),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  // Dark Overlay
                  Container(color: const Color(0x80000000)),

                  // Content
                  Column(
                    children: [
                      // Skip button
                      Padding(
                        padding: const EdgeInsets.only(top: 50, right: 20),
                        child: Align(
                          alignment: Alignment.topRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.pushReplacementNamed(context, AppRoutes.welcome);
                            },
                            child: Text('Skip', style: AppTheme.bodyStyle.copyWith(fontSize: 16, color: Colors.white)),
                          ),
                        ),
                      ),

                      // PageView với dữ liệu từng trang
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: OnboardingCubit.pages.length,
                          onPageChanged: (index) {
                            context.read<OnboardingCubit>().goToPage(index);
                          },
                          itemBuilder: (context, index) {
                            final pageData = OnboardingCubit.pages[index];
                            return _buildOnboardingPage(pageData);
                          },
                        ),
                      ),

                      // Dots indicator + buttons
                      Padding(
                        padding: const EdgeInsets.all(30),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (currentPage > 0)
                              IconButton(
                                onPressed: () {
                                  context.read<OnboardingCubit>().previousPage();
                                },
                                icon: const Icon(Icons.arrow_back, color: Colors.white),
                              )
                            else
                              const SizedBox(width: 80),

                            // Dots indicator
                            Row(
                              children: List.generate(OnboardingCubit.pages.length, (index) {
                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 5),
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: currentPage == index ? Colors.white : const Color(0x80FFFFFF),
                                  ),
                                );
                              }),
                            ),

                            if (currentPage < OnboardingCubit.pages.length - 1)
                              IconButton(
                                onPressed: () {
                                  context.read<OnboardingCubit>().nextPage();
                                },
                                icon: const Icon(Icons.arrow_forward, color: Colors.white),
                              )
                            else
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pushReplacementNamed(context, AppRoutes.login);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.blue,
                                ),
                                child: const Text('Get Started'),
                              ),
                          ],
                        ),
                      ),
                    ],
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

Widget _buildOnboardingPage(OnboardingPage data) {
  return Padding(
    padding: const EdgeInsets.all(20),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        Text(
          data.title, // Title sẽ thay đổi theo từng trang
          style: AppTheme.headlineStyle.copyWith(fontSize: 28, color: Colors.white),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),

        Text(
          data.description, // Description sẽ thay đổi theo từng trang
          style: AppTheme.bodyStyle.copyWith(fontSize: 16, color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}
