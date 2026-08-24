import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/data/repositories/user_repository.dart';
import 'package:mobile/data/services/token_service.dart';
import 'package:core_shared/models/check_in_model.dart';
import 'checkin_state.dart';

class CheckInCubit extends Cubit<CheckInState> {
  final UserRepository _userRepository;
  CheckInStatusModel? lastStatus;

  CheckInCubit(this._userRepository) : super(CheckInInitial());

  Future<void> fetchCheckInStatus() async {
    final userId = TokenService.getUserId();
    if (userId == null) {
      emit(const CheckInError('User not logged in'));
      return;
    }

    if (lastStatus == null) {
      emit(CheckInLoading());
    }

    try {
      final status = await _userRepository.getCheckInStatus(userId);
      lastStatus = status;
      emit(CheckInStatusLoaded(status));
    } catch (e) {
      if (lastStatus != null) {
        emit(CheckInStatusLoaded(lastStatus!));
      } else {
        emit(CheckInError(e.toString()));
      }
    }
  }

  Future<CheckInResultModel?> submitCheckIn(CheckInRequestModel request) async {
    final userId = TokenService.getUserId();
    if (userId == null) {
      emit(const CheckInError('User not logged in'));
      return null;
    }

    emit(CheckInSubmitting());
    try {
      final result = await _userRepository.submitCheckIn(userId, request);
      emit(CheckInSuccess(result));
      return result;
    } catch (e) {
      emit(CheckInError(e.toString()));
      return null;
    }
  }

  void reset() {
    lastStatus = null;
    emit(CheckInInitial());
  }
}
