import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/data/repositories/user_repository.dart';
import 'package:mobile/data/services/token_service.dart';
import 'user_state.dart';

class UserCubit extends Cubit<UserState> {
  final UserRepository _userRepository;

  UserCubit(this._userRepository) : super(UserInitial());

  Future<bool> fetchUserProfile() async {
    final userId = TokenService.getUserId();
    if (userId == null) {
      emit(const UserError('User not logged in'));
      return false;
    }

    // Load from cache first for instant UI response and offline support
    final cachedUser = TokenService.getCachedUser();
    if (cachedUser != null) {
      emit(UserLoaded(cachedUser));
    } else {
      emit(UserLoading());
    }

    try {
      final user = await _userRepository.getUserDetails(userId);
      await TokenService.saveUserCache(user);
      emit(UserLoaded(user));
      return true;
    } catch (e) {
      // If we don't have cache, emit error
      if (cachedUser == null) {
        emit(UserError(e.toString()));
      }
      return false;
    }
  }

  void clear() {
    emit(UserInitial());
  }
}
