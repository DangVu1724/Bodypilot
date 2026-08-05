import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/data/repositories/smart_swap_repository.dart';
import 'smart_swap_state.dart';

class SmartSwapCubit extends Cubit<SmartSwapState> {
  final SmartSwapRepository _repository;

  SmartSwapCubit([SmartSwapRepository? repository])
      : _repository = repository ?? smartSwapRepository,
        super(SmartSwapInitial());

  Future<void> fetchFoodCandidates(String foodId, {double currentServingQuantity = 100.0}) async {
    emit(SmartSwapLoading());
    try {
      final candidates = await _repository.getFoodSwapCandidates(
        foodId: foodId,
        currentServingQuantity: currentServingQuantity,
      );
      if (!isClosed) {
        emit(FoodSmartSwapLoaded(candidates));
      }
    } catch (e) {
      if (!isClosed) {
        emit(SmartSwapError(e.toString()));
      }
    }
  }
}
