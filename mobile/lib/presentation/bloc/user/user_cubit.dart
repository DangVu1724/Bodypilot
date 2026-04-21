import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/data/repositories/user_repository.dart';
import 'package:mobile/data/services/token_service.dart';
import 'user_state.dart';

class UserCubit extends Cubit<UserState> {
  final UserRepository _userRepository;

  UserCubit(this._userRepository) : super(UserInitial());

  Future<void> fetchUserProfile() async {
    final userId = TokenService.getUserId();
    if (userId == null) {
      emit(const UserError('User not logged in'));
      return;
    }

    emit(UserLoading());

    try {
      final user = await _userRepository.getUserDetails(userId);
      emit(UserLoaded(user));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }
}
