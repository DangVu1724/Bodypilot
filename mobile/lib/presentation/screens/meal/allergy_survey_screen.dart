import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/presentation/bloc/assessment/assessment_cubit.dart';
import 'package:mobile/presentation/bloc/assessment/assessment_state.dart';
import 'package:mobile/presentation/widgets/black_button_2.dart';
import 'package:mobile/presentation/screens/assessment/steps/diet_step.dart';
import 'package:mobile/presentation/screens/assessment/steps/disliked_foods_step.dart';
import 'package:mobile/presentation/screens/assessment/steps/budget_step.dart';
import 'package:core_shared/models/allergy_model.dart';

class MealPreferenceSurveyScreen extends StatefulWidget {
  const MealPreferenceSurveyScreen({super.key});

  @override
  State<MealPreferenceSurveyScreen> createState() => _MealPreferenceSurveyScreenState();
}

class _MealPreferenceSurveyScreenState extends State<MealPreferenceSurveyScreen> {
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
                content: Text('Đã cập nhật sở thích ăn uống thành công!'),
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
              MealSurveyIntroStep(onNext: () => nextPage(steps.length)),
              MealAllergyStep(onNext: () => nextPage(steps.length)),
              DietStep(onNext: () => nextPage(steps.length)),
              DislikedFoodsStep(onNext: () => nextPage(steps.length)),
              BudgetStep(
                onNext: () => nextPage(steps.length),
                onSubmit: () => context.read<AssessmentCubit>().submitMealPreferences(),
              ),
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
                        Navigator.of(context).pop(false);
                      }
                    },
                  ),
                  title: Text(
                    'Khảo sát Dinh dưỡng',
                    style: GoogleFonts.workSans(
                      color: const Color(0xFF1E293B),
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  centerTitle: true,
                  actions: [
                    if (currentIndex > 0)
                      Container(
                        margin: const EdgeInsets.only(right: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(
                          '$currentIndex/${steps.length - 1}',
                          style: AppTheme.semiboldStyle.copyWith(
                            fontSize: 14,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                  ],
                ),
                body: Column(
                  children: [
                    if (currentIndex > 0)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        child: LinearProgressIndicator(
                          value: currentIndex / (steps.length - 1),
                          backgroundColor: Colors.grey.shade100,
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                        ),
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
                              final slide = Tween(
                                begin: const Offset(0.1, 0),
                                end: Offset.zero,
                              ).animate(animation);

                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: slide,
                                  child: child,
                                ),
                              );
                            },
                            child: Container(
                              key: ValueKey(index),
                              child: steps[index],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class MealSurveyIntroStep extends StatelessWidget {
  final VoidCallback onNext;

  const MealSurveyIntroStep({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AssessmentCubit>().state;
    final isLoading = state.availableAllergies.isEmpty || state.availableDietTags.isEmpty;

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
              'Cá nhân hóa Thực đơn',
              style: AppTheme.headlineStyle.copyWith(color: Colors.white, fontSize: 26),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Hãy dành 1 phút để chia sẻ sở thích ăn uống của bạn. AI của BodyPilot sẽ thiết kế thực đơn khoa học, lành mạnh và phù hợp nhất với bạn.',
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

class MealAllergyStep extends StatefulWidget {
  final VoidCallback onNext;

  const MealAllergyStep({super.key, required this.onNext});

  @override
  State<MealAllergyStep> createState() => _MealAllergyStepState();
}

class _MealAllergyStepState extends State<MealAllergyStep> {
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    final initialNote = context.read<AssessmentCubit>().state.allergyNote;
    _noteController = TextEditingController(text: initialNote);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final assessmentState = context.watch<AssessmentCubit>().state;
    final selectedAllergies = assessmentState.selectedAllergies;
    final availableAllergies = assessmentState.availableAllergies;

    final displayAllergies = [
      if (availableAllergies.isNotEmpty)
        AllergyModel(
          id: 'none',
          name: 'Không bị dị ứng',
          code: 'NONE',
          description: 'Tôi không bị dị ứng với thực phẩm nào',
        ),
      ...availableAllergies,
    ];

    return Column(
      children: [
        const SizedBox(height: 20),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [AppTheme.primary, AppTheme.primary.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: Text(
                      'Dị ứng thực phẩm',
                      style: AppTheme.headlineStyle.copyWith(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Chọn các nhóm chất hoặc thực phẩm bạn bị dị ứng để AI tránh đưa vào thực đơn.',
                  style: AppTheme.bodyStyle.copyWith(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                availableAllergies.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: displayAllergies.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.1,
                        ),
                        itemBuilder: (context, index) {
                          final allergy = displayAllergies[index];
                          final isSelected = selectedAllergies.contains(allergy.code);
                          return _buildAllergyOption(
                            title: allergy.name,
                            icon: AssessmentState.getAllergyIcon(allergy.code),
                            isSelected: isSelected,
                            code: allergy.code,
                          );
                        },
                      ),
                
                const SizedBox(height: 32),
                Text(
                  'Mô tả chi tiết dị ứng (Ghi chú)',
                  style: AppTheme.semiboldStyle.copyWith(
                    fontSize: 16,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _noteController,
                  maxLines: 3,
                  onChanged: (value) {
                    context.read<AssessmentCubit>().setAllergyNote(value);
                  },
                  decoration: InputDecoration(
                    hintText: 'Ví dụ: dị ứng tôm hùm nặng, cua ghẹ nhẹ...',
                    hintStyle: AppTheme.bodyStyle.copyWith(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.all(16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppTheme.primary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        _buildBottomSection(selectedAllergies),
      ],
    );
  }

  Widget _buildAllergyOption({
    required String title,
    required IconData icon,
    required bool isSelected,
    required String code,
  }) {
    return GestureDetector(
      onTap: () => context.read<AssessmentCubit>().toggleAllergy(code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.grey.shade200,
            width: 2,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            else
              BoxShadow(
                color: Colors.grey.shade100,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Stack(
          children: [
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: Icon(Icons.check, size: 12, color: AppTheme.primary),
                ),
              ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 32,
                    color: isSelected ? Colors.white : AppTheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: AppTheme.semiboldStyle.copyWith(
                        fontSize: 14,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSection(List<String> selectedAllergies) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          if (selectedAllergies.isNotEmpty && !selectedAllergies.contains('NONE'))
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Đã chọn ${selectedAllergies.length} dị ứng',
                style: AppTheme.semiboldStyle.copyWith(
                  fontSize: 14,
                  color: AppTheme.primary,
                ),
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: BlackButton2(
              label: 'Tiếp tục',
              onPressed: selectedAllergies.isNotEmpty ? widget.onNext : null,
              borderRadius: 16,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}
