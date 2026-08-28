import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/admin_repository.dart';
import 'users_state.dart';

class UsersCubit extends Cubit<UsersState> {
  final AdminRepository adminRepository;

  UsersCubit({required this.adminRepository}) : super(UsersInitial());

  Future<void> fetchUsers({String? search, bool forceRefresh = false}) async {
    emit(UsersLoading());
    try {
      final users = await adminRepository.getAllUsers(search: search, forceRefresh: forceRefresh);
      emit(UsersSuccess(users, searchQuery: search));
    } catch (e) {
      final String msg = e.toString().replaceAll('Exception: ', '');
      emit(UsersFailure(msg));
    }
  }
}
