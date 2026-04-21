import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/data/repositories/auth_repository.dart';
import 'package:mobile/presentation/bloc/auth/signup_state.dart';

class SignupCubit extends Cubit<SignupState> {
  SignupCubit() : super(const SignupState());

  void fullNameChanged(String value) {
    emit(state.copyWith(fullName: value));
  }

  void emailChanged(String value) {
    final emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
    emit(state.copyWith(email: value, isValidEmail: emailRegex.hasMatch(value)));
  }

  void passwordChanged(String value) {
    emit(
      state.copyWith(
        password: value,
        isValidPassword: value.length >= 6,
        doPasswordsMatch: value == state.confirmPassword,
      ),
    );
  }

  void confirmPasswordChanged(String value) {
    emit(state.copyWith(confirmPassword: value, doPasswordsMatch: value == state.password));
  }

  void togglePasswordVisibility() {
    emit(state.copyWith(isPasswordVisible: !state.isPasswordVisible));
  }

  void toggleConfirmPasswordVisibility() {
    emit(state.copyWith(isConfirmPasswordVisible: !state.isConfirmPasswordVisible));
  }

  void termsAcceptedChanged(bool? value) {
    emit(state.copyWith(isTermsAccepted: value ?? false));
  }

  Future<void> submit() async {
    if (!state.isFormValid) {
      emit(
        state.copyWith(
          status: SignupStatus.failure,
          errorMessage: 'Please fill in all fields correctly and accept terms.',
        ),
      );
      return;
    }

    emit(state.copyWith(status: SignupStatus.loading, errorMessage: null));

    try {
      await authRepository.register(state.email, state.password, state.fullName);
      emit(state.copyWith(status: SignupStatus.success));
    } catch (e) {
      emit(state.copyWith(status: SignupStatus.failure, errorMessage: e.toString().replaceAll('Exception: ', '')));
    }
  }

  void reset() {
    emit(const SignupState());
  }
}
