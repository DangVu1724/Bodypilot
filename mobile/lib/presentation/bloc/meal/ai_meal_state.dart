import 'package:equatable/equatable.dart';
import 'package:core_shared/models/daily_eating_model.dart';

abstract class AiMealState extends Equatable {
  const AiMealState();

  @override
  List<Object?> get props => [];
}

class AiMealInitial extends AiMealState {}

class AiMealLoading extends AiMealState {}

class AiMealRegenerating extends AiMealState {
  final String feedbackText;

  const AiMealRegenerating(this.feedbackText);

  @override
  List<Object?> get props => [feedbackText];
}

class AiMealSuccess extends AiMealState {
  final List<DailyEatingModel> suggestions;
  final bool isFallback;
  final bool isRegenerated;

  const AiMealSuccess({
    required this.suggestions,
    required this.isFallback,
    this.isRegenerated = false,
  });

  @override
  List<Object?> get props => [suggestions, isFallback, isRegenerated];
}

class AiMealError extends AiMealState {
  final String message;

  const AiMealError(this.message);

  @override
  List<Object?> get props => [message];
}
