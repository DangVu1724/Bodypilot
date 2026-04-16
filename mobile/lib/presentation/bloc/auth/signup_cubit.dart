import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/presentation/bloc/auth/signup_state.dart';

class SignupCubit extends Cubit<SignupState> {
  SignupCubit() : super(const SignupState());

  bool _validateEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  bool _validatePassword(String password) {
    return password.length >= 6;
  }

  bool _checkPasswordsMatch(String password, String confirmPassword) {
    return password == confirmPassword;
  }

  void fullNameChanged(String value) {
    emit(state.copyWith(fullName: value));
  }

  void emailChanged(String value) {
    emit(state.copyWith(email: value, isValidEmail: _validateEmail(value)));
  }

  void passwordChanged(String value) {
    emit(
      state.copyWith(
        password: value,
        isValidPassword: _validatePassword(value),
        doPasswordsMatch: _checkPasswordsMatch(value, state.confirmPassword),
      ),
    );
  }

  void confirmPasswordChanged(String value) {
    emit(state.copyWith(confirmPassword: value, doPasswordsMatch: _checkPasswordsMatch(state.password, value)));
  }

  void togglePasswordVisibility() {
    emit(state.copyWith(isPasswordVisible: !state.isPasswordVisible));
  }

  void toggleConfirmPasswordVisibility() {
    emit(state.copyWith(isConfirmPasswordVisible: !state.isConfirmPasswordVisible));
  }

  void termsAcceptedChanged(bool? value) {
    emit(state.copyWith(isTermsAccepted: value));
  }

  Future<void> submit() async {
    if (!state.isFormValid) {
      emit(
        state.copyWith(
          status: SignupStatus.failure,
          errorMessage: 'Please fill all fields correctly and accept the terms.',
        ),
      );
      return;
    }

    emit(state.copyWith(status: SignupStatus.loading, errorMessage: null));

    try {
      // Simulate network call
      await Future.delayed(const Duration(seconds: 2));

      // On success
      emit(state.copyWith(status: SignupStatus.success));
    } catch (e) {
      // On failure
      emit(state.copyWith(status: SignupStatus.failure, errorMessage: e.toString()));
    }
  }

  void reset() {
    emit(const SignupState());
  }
}
