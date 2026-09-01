import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/data/repositories/auth_repository.dart';
import 'package:mobile/presentation/bloc/auth/login_state.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginCubit extends Cubit<LoginState> {
  LoginCubit() : super(const LoginState());

  bool _validateEmail(String email) {
    final emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  bool _validatePassword(String password) {
    return password.length >= 6;
  }

  void emailChanged(String value) {
    emit(state.copyWith(
      email: value,
      isValidEmail: _validateEmail(value),
      status: state.status == LoginStatus.failure ? LoginStatus.initial : state.status,
      errorMessage: state.status == LoginStatus.failure ? null : state.errorMessage,
    ));
  }

  void passwordChanged(String value) {
    emit(state.copyWith(
      password: value,
      isValidPassword: _validatePassword(value),
      status: state.status == LoginStatus.failure ? LoginStatus.initial : state.status,
      errorMessage: state.status == LoginStatus.failure ? null : state.errorMessage,
    ));
  }

  void togglePasswordVisibility() {
    emit(state.copyWith(isPasswordVisible: !state.isPasswordVisible));
  }

  Future<void> submit() async {
    if (!state.isFormValid) {
      emit(
        state.copyWith(
          status: LoginStatus.failure,
          errorMessage: 'Please enter a valid email and password.',
        ),
      );
      return;
    }

    emit(state.copyWith(status: LoginStatus.loading, errorMessage: null));

    try {
      final isComplete = await authRepository.login(state.email, state.password);
      emit(state.copyWith(status: LoginStatus.success, isProfileComplete: isComplete));
    } catch (e) {
      emit(state.copyWith(status: LoginStatus.failure, errorMessage: _formatErrorMessage(e)));
    }
  }

  Future<void> loginWithGoogle() async {
    emit(state.copyWith(status: LoginStatus.loading, errorMessage: null));

    try {
      await GoogleSignIn.instance.initialize(
        serverClientId: '517107633218-u5u15mb0iuc8j6po8s6mblrc37c6vvd2.apps.googleusercontent.com',
      );

      final GoogleSignInAccount googleUser = await GoogleSignIn.instance.authenticate();

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw Exception("Không thể lấy Google ID Token từ tài khoản của bạn.");
      }

      final isComplete = await authRepository.loginWithGoogle(idToken);
      emit(state.copyWith(status: LoginStatus.success, isProfileComplete: isComplete));
    } catch (e) {
      emit(state.copyWith(status: LoginStatus.failure, errorMessage: _formatErrorMessage(e)));
    }
  }

  String _formatErrorMessage(dynamic error) {
    final str = error.toString();
    if (str.contains('DioException') || str.contains('SocketException') || str.contains('connection error') || str.contains('Failed to connect') || str.contains('NetworkException') || str.contains('network_error')) {
      return 'Không thể kết nối đến máy chủ Backend. Vui lòng kiểm tra lại IP/Wifi hoặc môi trường chạy.';
    }
    if (str.contains('Bad credentials') || str.contains('401') || str.contains('Invalid email or password')) {
      return 'Email hoặc mật khẩu không chính xác.';
    }
    return str.replaceAll('Exception: ', '');
  }

  void reset() {
    emit(const LoginState());
  }
}
