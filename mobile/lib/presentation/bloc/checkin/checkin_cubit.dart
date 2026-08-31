import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/data/repositories/user_repository.dart';
import 'package:mobile/data/services/token_service.dart';
import 'package:core_shared/models/check_in_model.dart';
import 'checkin_state.dart';

class CheckInCubit extends Cubit<CheckInState> {
  final UserRepository _userRepository;
  CheckInStatusModel? lastStatus;
  String? _loadedUserId;

  CheckInCubit(this._userRepository) : super(CheckInInitial());

  Future<void> fetchCheckInStatus({bool force = false}) async {
    final userId = TokenService.getUserId();
    if (userId == null) {
      lastStatus = null;
      _loadedUserId = null;
      emit(CheckInInitial());
      return;
    }

    if (userId != _loadedUserId || force) {
      lastStatus = null;
      _loadedUserId = userId;
    }

    if (lastStatus == null) {
      emit(CheckInLoading());
    }

    try {
      final status = await _userRepository.getCheckInStatus(userId);
      lastStatus = status;
      _loadedUserId = userId;
      emit(CheckInStatusLoaded(status));
    } catch (e) {
      if (lastStatus != null && _loadedUserId == userId) {
        emit(CheckInStatusLoaded(lastStatus!));
      } else {
        lastStatus = null;
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
    _loadedUserId = null;
    emit(CheckInInitial());
  }
}
