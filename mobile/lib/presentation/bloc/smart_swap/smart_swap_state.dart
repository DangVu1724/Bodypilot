import 'package:equatable/equatable.dart';
import 'package:mobile/data/models/food_smart_swap_model.dart';

abstract class SmartSwapState extends Equatable {
  const SmartSwapState();

  @override
  List<Object?> get props => [];
}

class SmartSwapInitial extends SmartSwapState {}

class SmartSwapLoading extends SmartSwapState {}

class FoodSmartSwapLoaded extends SmartSwapState {
  final List<FoodSmartSwapCandidateModel> candidates;

  const FoodSmartSwapLoaded(this.candidates);

  @override
  List<Object?> get props => [candidates];
}

class SmartSwapError extends SmartSwapState {
  final String message;

  const SmartSwapError(this.message);

  @override
  List<Object?> get props => [message];
}
