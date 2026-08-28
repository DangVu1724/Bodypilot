import 'package:core_shared/core_shared.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/page_response_model.dart';

abstract class IngredientsState extends Equatable {
  const IngredientsState();

  @override
  List<Object?> get props => [];
}

class IngredientsInitial extends IngredientsState {}

class IngredientsLoading extends IngredientsState {}

class IngredientsSuccess extends IngredientsState {
  final PageResponseModel<FoodModel> pageData;
  final String? searchQuery;
  final int currentPage;

  const IngredientsSuccess(this.pageData, {this.searchQuery, this.currentPage = 0});

  @override
  List<Object?> get props => [pageData, searchQuery, currentPage];
}

class IngredientsFailure extends IngredientsState {
  final String message;

  const IngredientsFailure(this.message);

  @override
  List<Object?> get props => [message];
}
