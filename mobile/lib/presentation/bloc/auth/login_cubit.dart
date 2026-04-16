import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/presentation/bloc/auth/login_state.dart';

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
    emit(state.copyWith(email: value, isValidEmail: _validateEmail(value)));
  }

  void passwordChanged(String value) {
    emit(state.copyWith(password: value, isValidPassword: _validatePassword(value)));
  }

  void togglePasswordVisibility() {
    emit(state.copyWith(isPasswordVisible: !state.isPasswordVisible));
  }

  Future<void> submit() async {
    if (!state.isFormValid) {
      emit(
        state.copyWith(
          status: LoginStatus.failure,
          errorMessage: 'Please enter a valid email and password with at least 6 characters.',
        ),
      );
      return;
    }

    emit(state.copyWith(status: LoginStatus.loading, errorMessage: null));

    try {
      await Future.delayed(const Duration(seconds: 2));
      emit(state.copyWith(status: LoginStatus.success));
    } catch (e) {
      emit(state.copyWith(status: LoginStatus.failure, errorMessage: e.toString()));
    }
  }

  void reset() {
    emit(const LoginState());
  }
}
