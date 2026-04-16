import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/presentation/bloc/assessment/assessment_cubit.dart';
import 'package:mobile/presentation/screens/assessment/steps/age_step.dart';
import 'package:mobile/presentation/screens/assessment/steps/body_step.dart';
import 'package:mobile/presentation/screens/assessment/steps/diet_step.dart';
import 'package:mobile/presentation/screens/assessment/steps/experience_step.dart';
import 'package:mobile/presentation/screens/assessment/steps/gender_step.dart';
import 'package:mobile/presentation/screens/assessment/steps/goal_step.dart';

class AssessmentScreen extends StatefulWidget {
  const AssessmentScreen({super.key});

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  final PageController _controller = PageController();
  int currentIndex = 0;

  void nextPage() {
    _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease);
  }

  @override
  Widget build(BuildContext context) {
    final steps = [
      GoalStep(onNext: nextPage),
      GenderStep(onNext: nextPage),
      BodyStep(onNext: nextPage),
      AgeStep(onNext: nextPage),
      ExperienceStep(onNext: nextPage),
      DietStep(onNext: nextPage),
    ];

    return BlocProvider(
      create: (_) => AssessmentCubit(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Assessment'),
          actions: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(20)),
              child: Text(
                '${currentIndex + 1}/${steps.length}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            /// progress bar
            LinearProgressIndicator(value: (currentIndex + 1) / steps.length),

            Expanded(
              child: PageView.builder(
                controller: _controller,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: steps.length,
                onPageChanged: (index) {
                  setState(() {
                    currentIndex = index;
                  });
                },
                itemBuilder: (context, index) => Padding(padding: const EdgeInsets.all(16), child: steps[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
