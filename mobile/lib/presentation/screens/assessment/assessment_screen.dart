import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/presentation/bloc/assessment/assessment_cubit.dart';
import 'package:mobile/presentation/bloc/assessment/assessment_state.dart';
import 'package:mobile/presentation/screens/assessment/steps/age_step.dart';
import 'package:mobile/presentation/screens/assessment/steps/body_step.dart';
import 'package:mobile/presentation/screens/assessment/steps/condition_step.dart';
import 'package:mobile/presentation/screens/assessment/steps/experience_step.dart';
import 'package:mobile/presentation/screens/assessment/steps/gender_step.dart';
import 'package:mobile/presentation/screens/assessment/steps/goal_step.dart';
import 'package:mobile/presentation/screens/assessment/steps/injury_step.dart';
import 'package:mobile/presentation/screens/assessment/steps/target_weight_step.dart';
import 'package:mobile/presentation/screens/assessment/steps/activity_level_step.dart';

class AssessmentScreen extends StatefulWidget {
  const AssessmentScreen({super.key});

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  final PageController _controller = PageController();
  int currentIndex = 0;

  void nextPage(int stepCount) {
    if (currentIndex < stepCount - 1) {
      _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void previousPage() {
    if (currentIndex > 0) {
      _controller.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    late final List<Widget> steps;
    steps = [
      GoalStep(onNext: () => nextPage(steps.length)),
      GenderStep(onNext: () => nextPage(steps.length)),
      AgeStep(onNext: () => nextPage(steps.length)),
      BodyStep(onNext: () => nextPage(steps.length)),
      TargetWeightStep(onNext: () => nextPage(steps.length)),
      ExperienceStep(onNext: () => nextPage(steps.length)),
      ActivityLevelStep(onNext: () => nextPage(steps.length)),
      ConditionStep(onNext: () => nextPage(steps.length)),
      InjuryStep(onNext: () => nextPage(steps.length)),
    ];

    return BlocProvider(
      create: (_) => AssessmentCubit(),
      child: BlocListener<AssessmentCubit, AssessmentState>(
        listener: (context, state) {
          if (state.status == AssessmentStatus.success) {
            Navigator.pushReplacementNamed(context, '/home');
          } else if (state.status == AssessmentStatus.failure) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Có lỗi xảy ra khi lưu dữ liệu. Vui lòng thử lại.')));
          }
        },
        child: WillPopScope(
          onWillPop: () async {
            if (currentIndex > 0) {
              previousPage();
              return false;
            }
            return false;
          },
          child: Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              leading: currentIndex > 0
                  ? IconButton(icon: const Icon(Icons.arrow_back_ios_new), onPressed: previousPage)
                  : null,
              title: const Text('Assessment'),
              actions: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    '${currentIndex + 1}/${steps.length}',
                    style: AppTheme.semiboldStyle.copyWith(fontSize: 16),
                  ),
                ),
              ],
            ),
            body: Column(
              children: [
                /// progress bar
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  child: LinearProgressIndicator(value: (currentIndex + 1) / steps.length),
                ),

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
                    itemBuilder: (context, index) {
                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) {
                          final slide = Tween(begin: const Offset(0.1, 0), end: Offset.zero).animate(animation);

                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(position: slide, child: child),
                          );
                        },
                        child: Container(key: ValueKey(index), padding: const EdgeInsets.all(16), child: steps[index]),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
