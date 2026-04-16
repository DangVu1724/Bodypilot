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

    return Column(
      children: [
        const SizedBox(height: 20),

        Text(
          'Bạn bao nhiêu tuổi?',
          style: GoogleFonts.workSans(fontSize: 32, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8),

        Text(
          'Vuốt để chọn tuổi của bạn',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 20),

        SizedBox(
          height: screenHeight * 0.6,
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
                diameterRatio: 1.1,
                perspective: 0.0015,
                physics: const FixedExtentScrollPhysics(),
                onSelectedItemChanged: (index) {
                  context.read<AssessmentCubit>().selectAge(index + 1);
                },
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: 100,
                  builder: (context, index) {
                    final age = index + 1;
                    final selectedAge = context.watch<AssessmentCubit>().state.selectedAge;
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
                          style: GoogleFonts.workSans(
                            fontSize: diff == 0 ? 72 : 68,
                            fontWeight: FontWeight.bold,
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

        SizedBox(
          width: double.infinity,
          child: BlackButton2(
            label: 'Continue',
            onPressed: () {
              widget.onNext();
            },
            borderRadius: 12,
            padding: const EdgeInsets.symmetric(vertical: 18),
          ),
        ),
      ],
    );
  }
}
