import 'package:core_shared/core_shared.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/page_response_model.dart';

abstract class ExercisesState extends Equatable {
  const ExercisesState();

  @override
  List<Object?> get props => [];
}

class ExercisesInitial extends ExercisesState {}

class ExercisesLoading extends ExercisesState {}

class ExercisesSuccess extends ExercisesState {
  final PageResponseModel<ExerciseModel> pageData;
  final String? searchQuery;
  final int currentPage;

  const ExercisesSuccess(this.pageData, {this.searchQuery, this.currentPage = 0});

  @override
  List<Object?> get props => [pageData, searchQuery, currentPage];
}

class ExercisesFailure extends ExercisesState {
  final String message;

  const ExercisesFailure(this.message);

  @override
  List<Object?> get props => [message];
}
