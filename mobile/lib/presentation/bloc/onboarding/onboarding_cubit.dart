import 'package:flutter_bloc/flutter_bloc.dart';

class OnboardingPage {
  final String image;
  final String title;
  final String description;

  const OnboardingPage({required this.image, required this.title, required this.description});
}

class OnboardingCubit extends Cubit<int> {
  OnboardingCubit() : super(0);

  static const List<OnboardingPage> pages = [
    OnboardingPage(
      image: 'assets/images/boxing.png',
      title: 'Personalized Workout Plans',
      description: 'Get workout plans tailored to your fitness goals',
    ),
    OnboardingPage(
      image: 'assets/images/equipments.png',
      title: 'Smart Nutrition Guide',
      description: 'Track your meals and get personalized advice',
    ),
    OnboardingPage(
      image: 'assets/images/fruit.png',
      title: 'AI Fitness Coach',
      description: 'Real-time feedback using AI technology',
    ),
    OnboardingPage(
      image: 'assets/images/heart.png',
      title: 'Track Your Progress',
      description: 'Monitor your improvements with analytics',
    ),
    OnboardingPage(
      image: 'assets/images/yoga.png',
      title: 'Join Our Community',
      description: 'Connect with others and stay motivated',
    ),
  ];

  void nextPage() {
    if (state < pages.length - 1) emit(state + 1);
  }

  void previousPage() {
    if (state > 0) emit(state - 1);
  }

  void goToPage(int index) {
    if (index >= 0 && index < pages.length) emit(index);
  }
}
