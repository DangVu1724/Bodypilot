import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/admin_repository.dart';
import 'dishes_state.dart';

class DishesCubit extends Cubit<DishesState> {
  final AdminRepository adminRepository;

  DishesCubit({required this.adminRepository}) : super(DishesInitial());

  Future<void> fetchDishes({
    int page = 0,
    int size = 20,
    String? search,
    String? categoryId,
  }) async {
    emit(DishesLoading());
    try {
      final pageData = await adminRepository.getAllDishes(
        page: page,
        size: size,
        search: search,
        categoryId: categoryId,
      );
      emit(DishesSuccess(pageData, searchQuery: search, currentPage: page));
    } catch (e) {
      final String msg = e.toString().replaceAll('Exception: ', '');
      emit(DishesFailure(msg));
    }
  }

  Future<bool> deleteDish(String id) async {
    try {
      await adminRepository.deleteFood(id);
      if (state is DishesSuccess) {
        final currentState = state as DishesSuccess;
        fetchDishes(page: currentState.currentPage, search: currentState.searchQuery);
      }
      return true;
    } catch (e) {
      emit(DishesFailure('Lỗi xóa món ăn: $e'));
      return false;
    }
  }
}
