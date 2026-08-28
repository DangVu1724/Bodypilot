import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/admin_repository.dart';
import 'ingredients_state.dart';

class IngredientsCubit extends Cubit<IngredientsState> {
  final AdminRepository adminRepository;

  IngredientsCubit({required this.adminRepository}) : super(IngredientsInitial());

  Future<void> fetchIngredients({
    int page = 0,
    int size = 20,
    String? search,
    String? categoryId,
  }) async {
    emit(IngredientsLoading());
    try {
      final pageData = await adminRepository.getAllIngredients(
        page: page,
        size: size,
        search: search,
        categoryId: categoryId,
      );
      emit(IngredientsSuccess(pageData, searchQuery: search, currentPage: page));
    } catch (e) {
      final String msg = e.toString().replaceAll('Exception: ', '');
      emit(IngredientsFailure(msg));
    }
  }

  Future<bool> deleteIngredient(String id) async {
    try {
      await adminRepository.deleteFood(id);
      if (state is IngredientsSuccess) {
        final currentState = state as IngredientsSuccess;
        fetchIngredients(page: currentState.currentPage, search: currentState.searchQuery);
      }
      return true;
    } catch (e) {
      emit(IngredientsFailure('Lỗi xóa nguyên liệu: $e'));
      return false;
    }
  }
}
