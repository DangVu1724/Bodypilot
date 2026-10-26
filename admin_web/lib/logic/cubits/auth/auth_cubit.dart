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
      final Map<String, dynamic> authPayload = Map<String, dynamic>.from(resData as Map);
      final Map<String, dynamic> userData = (authPayload['user'] is Map)
          ? Map<String, dynamic>.from(authPayload['user'] as Map)
          : authPayload;

      final String? token = authPayload['token']?.toString();
      final roleStr = (userData['role'] ?? authPayload['role'] ?? '').toString().toUpperCase();

      if (roleStr == 'ADMIN' && token != null && token.isNotEmpty) {
        apiClient.setAuthToken(token);
        emit(AuthSuccess(userData));
      } else {
        apiClient.setAuthToken(null);
        emit(const AuthFailure('Tài khoản của bạn là Customer (Khách hàng). Chỉ tài khoản ADMIN mới được truy cập!'));
      }
    } catch (e) {
      apiClient.setAuthToken(null);
      final String msg = e.toString().replaceAll('Exception: ', '');
      emit(AuthFailure('Đăng nhập thất bại: $msg'));
    }
  }

  void logout() {
    apiClient.setAuthToken(null);
    emit(AuthInitial());
  }
}
