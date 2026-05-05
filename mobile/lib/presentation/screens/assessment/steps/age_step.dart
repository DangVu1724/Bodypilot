import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/presentation/bloc/assessment/assessment_cubit.dart';
import 'package:mobile/presentation/widgets/black_button_2.dart';

class AgeStep extends StatefulWidget {
  final VoidCallback onNext;

  const AgeStep({super.key, required this.onNext});

  @override
  State<AgeStep> createState() => _AgeStepState();
}

class _AgeStepState extends State<AgeStep> {
  late FixedExtentScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    final selectedAge = context.read<AssessmentCubit>().state.selectedAge;
    _scrollController = FixedExtentScrollController(initialItem: selectedAge - 1);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final selectedAge = context.watch<AssessmentCubit>().state.selectedAge;

    return Column(
      children: [
        const SizedBox(height: 20),

        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [AppTheme.primary, AppTheme.primary.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            'Tuổi của bạn',
            style: AppTheme.headlineStyle.copyWith(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Bạn bao nhiêu tuổi?',
          style: AppTheme.semiboldStyle.copyWith(fontSize: 18, color: Colors.black87),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Vuốt để chọn tuổi của bạn',
          style: AppTheme.bodyStyle.copyWith(color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 10),

        SizedBox(
          height: screenHeight * 0.5,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 🎯 Selected highlight behind the selected item
              Container(
                height: 110,
                width: 170,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: AppTheme.primary, width: 3),
                ),
              ),

              ListWheelScrollView.useDelegate(
                controller: _scrollController,
                itemExtent: 90,
                diameterRatio: 1.9,
                perspective: 0.0015,
                physics: const FixedExtentScrollPhysics(),
                onSelectedItemChanged: (index) {
                  context.read<AssessmentCubit>().selectAge(index + 1);
                },
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: 100,
                  builder: (context, index) {
                    final age = index + 1;
                    final diff = (age - selectedAge).abs();

                    final scale = diff == 0
                        ? 1.0
                        : diff == 1
                        ? 0.75
                        : 0.55;

                    return Center(
                      child: AnimatedScale(
                        scale: scale,
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          '$age',
                          style: AppTheme.headlineStyle.copyWith(
                            fontSize: diff == 0 ? 64 : 60,
                            color: diff == 0 ? Colors.white : Colors.grey.shade500,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        const Spacer(),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 20, offset: const Offset(0, -5))],
          ),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: BlackButton2(
                  label: 'Tiếp tục',
                  onPressed: () {
                    widget.onNext();
                  },
                  borderRadius: 16,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
