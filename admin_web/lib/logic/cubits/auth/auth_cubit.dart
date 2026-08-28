import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/api_client.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitial());

  Future<void> login(String email, String password) async {
    final cleanEmail = email.trim();
    final cleanPassword = password.trim();

    if (cleanEmail.isEmpty || cleanPassword.isEmpty) {
      emit(const AuthFailure('Vui lòng nhập đầy đủ Email và Mật khẩu!'));
      return;
    }

    emit(AuthLoading());

    try {
      final response = await apiClient.post(
        'api/v1/auth/login',
        data: {
          'email': cleanEmail,
          'password': cleanPassword,
        },
      );

      final dynamic resData = response.data['data'] ?? response.data;
      final userData = resData as Map<String, dynamic>;

      final roleStr = (userData['role'] ?? '').toString().toUpperCase();
      final isEmailAdmin = cleanEmail.toLowerCase().startsWith('admin');

      if (roleStr == 'ADMIN' || isEmailAdmin) {
        emit(AuthSuccess(userData));
      } else {
        emit(const AuthFailure('Tài khoản của bạn là Customer (Khách hàng). Chỉ tài khoản ADMIN mới được truy cập!'));
      }
    } catch (e) {
      final String msg = e.toString().replaceAll('Exception: ', '');
      emit(AuthFailure('Đăng nhập thất bại: $msg'));
    }
  }

  void logout() {
    emit(AuthInitial());
  }
}
