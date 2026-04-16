import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/presentation/bloc/assessment/assessment_cubit.dart';
import 'package:mobile/presentation/widgets/black_button_2.dart';

class BodyStep extends StatefulWidget {
  final VoidCallback onNext;

  const BodyStep({super.key, required this.onNext});

  @override
  State<BodyStep> createState() => _BodyStepState();
}

class _BodyStepState extends State<BodyStep> {
  late FixedExtentScrollController _heightController;
  late FixedExtentScrollController _weightController;

  static const int minHeight = 100;
  static const int maxHeight = 220;
  static const int minWeight = 30;
  static const int maxWeight = 150;
  static const double itemExtent = 80;

  @override
  void initState() {
    super.initState();
    final assessmentState = context.read<AssessmentCubit>().state;
    _heightController = FixedExtentScrollController(initialItem: assessmentState.selectedHeight - minHeight);
    _weightController = FixedExtentScrollController(initialItem: assessmentState.selectedWeight - minWeight);
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Widget _buildMeasurementWheel({
    required String label,
    required String unit,
    required int min,
    required int max,
    required int selectedValue,
    required FixedExtentScrollController controller,
    required ValueChanged<int> onSelectedItemChanged,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: GoogleFonts.workSans(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                ListWheelScrollView.useDelegate(
                  controller: controller,
                  itemExtent: itemExtent,
                  diameterRatio: 1.2,
                  perspective: 0.0015,
                  physics: const FixedExtentScrollPhysics(),
                  onSelectedItemChanged: (index) {
                    onSelectedItemChanged(min + index);
                  },
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: max - min + 1,
                    builder: (context, index) {
                      final value = min + index;
                      final diff = (value - selectedValue).abs();
                      final scale = diff == 0
                          ? 1.0
                          : diff == 1
                          ? 0.75
                          : 0.55;
                      final color = diff == 0 ? AppTheme.primary : Colors.grey.shade500;

                      return Center(
                        child: AnimatedScale(
                          scale: scale,
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            '$value',
                            style: GoogleFonts.workSans(
                              fontSize: diff == 0 ? 54 : 38,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  height: itemExtent,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.primary, width: 2),
                    color: AppTheme.primary.withOpacity(0.12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('$selectedValue $unit', style: GoogleFonts.workSans(fontSize: 20, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final assessmentState = context.watch<AssessmentCubit>().state;

    return Column(
      children: [
        const SizedBox(height: 20),
        Text(
          'Chiều cao và cân nặng của bạn là bao nhiêu?',
          style: GoogleFonts.workSans(fontSize: 32, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Vuốt các con số để chọn chiều cao và cân nặng cùng một lúc',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildMeasurementWheel(
                label: 'Chiều cao',
                unit: 'cm',
                min: minHeight,
                max: maxHeight,
                selectedValue: assessmentState.selectedHeight,
                controller: _heightController,
                onSelectedItemChanged: (value) {
                  context.read<AssessmentCubit>().selectHeight(value);
                },
              ),
              const SizedBox(width: 16),
              _buildMeasurementWheel(
                label: 'Cân nặng',
                unit: 'kg',
                min: minWeight,
                max: maxWeight,
                selectedValue: assessmentState.selectedWeight,
                controller: _weightController,
                onSelectedItemChanged: (value) {
                  context.read<AssessmentCubit>().selectWeight(value);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: BlackButton2(
            label: 'Continue',
            onPressed: widget.onNext,
            borderRadius: 16,
            padding: const EdgeInsets.symmetric(vertical: 18),
          ),
        ),
      ],
    );
  }
}

class RulerPicker extends StatefulWidget {
  final int min;
  final int max;
  final double step;
  final double initialValue;
  final Function(double) onChanged;
  final String unit;
  final Axis axis;

  const RulerPicker({
    super.key,
    required this.min,
    required this.max,
    required this.step,
    required this.initialValue,
    required this.onChanged,
    required this.unit,
    this.axis = Axis.vertical,
  });

  @override
  State<RulerPicker> createState() => _RulerPickerState();
}

class _RulerPickerState extends State<RulerPicker> {
  late ScrollController _controller;
  late double _value;

  static const double itemExtent = 20;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;

    final initialIndex = ((_value - widget.min) / widget.step).round();

    _controller = ScrollController(initialScrollOffset: initialIndex * itemExtent);
  }

  double _getValue() {
    final index = (_controller.offset / itemExtent).round();
    final value = widget.min + index * widget.step;
    return value.clamp(widget.min.toDouble(), widget.max.toDouble());
  }

  @override
  Widget build(BuildContext context) {
    final totalItems = ((widget.max - widget.min) / widget.step).round() + 1;

    return Column(
      children: [
        Text(
          '${_value.toStringAsFixed(0)} ${widget.unit}',
          style: GoogleFonts.workSans(fontSize: 48, fontWeight: FontWeight.bold, color: AppTheme.primary),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final padding = constraints.maxHeight / 2 - itemExtent / 2;

              return Stack(
                alignment: Alignment.center,
                children: [
                  NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification is ScrollUpdateNotification) {
                        final newValue = _getValue();
                        if (newValue != _value) {
                          setState(() {
                            _value = newValue;
                          });
                          widget.onChanged(_value);
                        }
                      }
                      return false;
                    },
                    child: ListView.builder(
                      controller: _controller,
                      scrollDirection: widget.axis,
                      padding: widget.axis == Axis.horizontal
                          ? EdgeInsets.symmetric(horizontal: padding)
                          : EdgeInsets.symmetric(vertical: padding),
                      itemCount: totalItems,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        final value = widget.min + index * widget.step;
                        final isMajor = index % 5 == 0;
                        final isSelected = value == _value;
                        final color = isSelected ? AppTheme.primary : Colors.grey.shade600;

                        if (widget.axis == Axis.horizontal) {
                          return SizedBox(
                            width: itemExtent,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(width: 2, height: isMajor ? 60 : 35, color: color),
                                if (isMajor) const SizedBox(height: 6),
                                if (isMajor)
                                  Text(
                                    value.toStringAsFixed(0),
                                    style: GoogleFonts.workSans(
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w400,
                                      color: color,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }

                        return SizedBox(
                          height: itemExtent,
                          width: double.infinity,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(width: 3, height: isMajor ? 60 : 35, color: color),
                              if (isMajor) const SizedBox(width: 8),
                              if (isMajor)
                                Text(
                                  value.toStringAsFixed(0),
                                  style: GoogleFonts.workSans(
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w400,
                                    color: color,
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Container(height: 4, margin: const EdgeInsets.symmetric(horizontal: 20), color: AppTheme.primary),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
