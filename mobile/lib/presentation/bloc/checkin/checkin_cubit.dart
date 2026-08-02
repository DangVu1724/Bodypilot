import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/data/repositories/user_repository.dart';
import 'package:mobile/data/services/token_service.dart';
import 'package:core_shared/models/check_in_model.dart';
import 'checkin_state.dart';

class CheckInCubit extends Cubit<CheckInState> {
  final UserRepository _userRepository;

  CheckInCubit(this._userRepository) : super(CheckInInitial());

  Future<void> fetchCheckInStatus() async {
    final userId = TokenService.getUserId();
    if (userId == null) {
      emit(const CheckInError('User not logged in'));
      return;
    }

    emit(CheckInLoading());
    try {
      final status = await _userRepository.getCheckInStatus(userId);
      emit(CheckInStatusLoaded(status));
    } catch (e) {
      emit(CheckInError(e.toString()));
    }
  }

  Future<void> submitCheckIn(CheckInRequestModel request) async {
    final userId = TokenService.getUserId();
    if (userId == null) {
      emit(const CheckInError('User not logged in'));
      return;
    }

    emit(CheckInSubmitting());
    try {
      final result = await _userRepository.submitCheckIn(userId, request);
      emit(CheckInSuccess(result));
    } catch (e) {
      emit(CheckInError(e.toString()));
    }
  }

  void reset() {
    emit(CheckInInitial());
  }
}
