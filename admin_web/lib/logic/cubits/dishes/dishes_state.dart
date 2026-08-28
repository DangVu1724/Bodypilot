import 'package:core_shared/core_shared.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/page_response_model.dart';

abstract class DishesState extends Equatable {
  const DishesState();

  @override
  List<Object?> get props => [];
}

class DishesInitial extends DishesState {}

class DishesLoading extends DishesState {}

class DishesSuccess extends DishesState {
  final PageResponseModel<FoodModel> pageData;
  final String? searchQuery;
  final int currentPage;

  const DishesSuccess(this.pageData, {this.searchQuery, this.currentPage = 0});

  @override
  List<Object?> get props => [pageData, searchQuery, currentPage];
}

class DishesFailure extends DishesState {
  final String message;

  const DishesFailure(this.message);

  @override
  List<Object?> get props => [message];
}
