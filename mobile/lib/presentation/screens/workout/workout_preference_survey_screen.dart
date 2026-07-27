import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/presentation/bloc/assessment/assessment_cubit.dart';
import 'package:mobile/presentation/bloc/assessment/assessment_state.dart';
import 'package:mobile/presentation/screens/assessment/steps/goal_step.dart';
import 'package:mobile/presentation/screens/assessment/steps/activity_level_step.dart';
import 'package:mobile/presentation/screens/assessment/steps/condition_step.dart';
import 'package:mobile/presentation/screens/assessment/steps/injury_step.dart';

class WorkoutPreferenceSurveyScreen extends StatefulWidget {
  const WorkoutPreferenceSurveyScreen({super.key});

  @override
  State<WorkoutPreferenceSurveyScreen> createState() => _WorkoutPreferenceSurveyScreenState();
}

class _WorkoutPreferenceSurveyScreenState extends State<WorkoutPreferenceSurveyScreen> {
  final PageController _controller = PageController();
  int currentIndex = 0;

  void nextPage(int stepCount) {
    if (currentIndex < stepCount - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void previousPage() {
    if (currentIndex > 0) {
      _controller.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AssessmentCubit(),
      child: BlocListener<AssessmentCubit, AssessmentState>(
        listener: (context, state) {
          if (state.status == AssessmentStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã cập nhật sở thích tập luyện thành công!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop(true);
          } else if (state.status == AssessmentStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Có lỗi xảy ra khi lưu thông tin. Vui lòng thử lại.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Builder(
          builder: (context) {
            late final List<Widget> steps;
            steps = [
              WorkoutSurveyIntroStep(onNext: () => nextPage(steps.length)),
              GoalStep(onNext: () => nextPage(steps.length)),
              ActivityLevelStep(onNext: () => nextPage(steps.length)),
              ConditionStep(onNext: () => nextPage(steps.length)),
              InjuryStep(onNext: () => nextPage(steps.length)),
            ];

            return WillPopScope(
              onWillPop: () async {
                if (currentIndex > 0) {
                  previousPage();
                  return false;
                }
                return true;
              },
              child: Scaffold(
                backgroundColor: Colors.white,
                appBar: AppBar(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E293B)),
                    onPressed: () {
                      if (currentIndex > 0) {
                        previousPage();
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: steps.isEmpty ? 0 : (currentIndex / (steps.length - 1)),
                            backgroundColor: Colors.grey.shade100,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${currentIndex + 1}/${steps.length}',
                        style: GoogleFonts.workSans(
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                body: PageView(
                  controller: _controller,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() {
                      currentIndex = index;
                    });
                  },
                  children: steps,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class WorkoutSurveyIntroStep extends StatelessWidget {
  final VoidCallback onNext;

  const WorkoutSurveyIntroStep({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AssessmentCubit>().state;
    final isLoading = state.availableInjuries.isEmpty || state.availableConditions.isEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome,
              size: 80,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 32),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [AppTheme.primary, AppTheme.primary.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            child: Text(
              'Cá nhân hóa Lịch tập',
              style: AppTheme.headlineStyle.copyWith(color: Colors.white, fontSize: 26),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Hãy dành 1 phút để chia sẻ thể trạng và chấn thương của bạn. AI của BodyPilot sẽ thiết kế lịch tập an toàn, hiệu quả và phù hợp nhất với bạn.',
            style: AppTheme.bodyStyle.copyWith(
              color: Colors.grey.shade600,
              fontSize: 15,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading ? null : onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                disabledBackgroundColor: Colors.grey.shade200,
              ),
              child: isLoading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Đang tải dữ liệu...',
                          style: AppTheme.semiboldStyle.copyWith(
                            color: Colors.grey.shade500,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      'Bắt đầu khảo sát',
                      style: AppTheme.semiboldStyle.copyWith(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
