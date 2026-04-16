import 'package:equatable/equatable.dart';

enum SignupStatus { initial, loading, success, failure }

class SignupState extends Equatable {
  final SignupStatus status;
  final String fullName;
  final String email;
  final String password;
  final String confirmPassword;
  final bool isTermsAccepted;
  final bool isPasswordVisible;
  final bool isConfirmPasswordVisible;
  final String? errorMessage;

  final bool isValidEmail;
  final bool isValidPassword;
  final bool doPasswordsMatch;

  const SignupState({
    this.status = SignupStatus.initial,
    this.fullName = '',
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.isTermsAccepted = false,
    this.isPasswordVisible = false,
    this.isConfirmPasswordVisible = false,
    this.errorMessage,
    this.isValidEmail = false,
    this.isValidPassword = false,
    this.doPasswordsMatch = false,
  });

  bool get isFormValid {
    return fullName.trim().isNotEmpty && isValidEmail && isValidPassword && doPasswordsMatch && isTermsAccepted;
  }

  SignupState copyWith({
    SignupStatus? status,
    String? fullName,
    String? email,
    String? password,
    String? confirmPassword,
    bool? isTermsAccepted,
    bool? isPasswordVisible,
    bool? isConfirmPasswordVisible,
    String? errorMessage,
    bool? isValidEmail,
    bool? isValidPassword,
    bool? doPasswordsMatch,
  }) {
    return SignupState(
      status: status ?? this.status,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      isTermsAccepted: isTermsAccepted ?? this.isTermsAccepted,
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
      isConfirmPasswordVisible: isConfirmPasswordVisible ?? this.isConfirmPasswordVisible,
      errorMessage: errorMessage ?? this.errorMessage,
      isValidEmail: isValidEmail ?? this.isValidEmail,
      isValidPassword: isValidPassword ?? this.isValidPassword,
      doPasswordsMatch: doPasswordsMatch ?? this.doPasswordsMatch,
    );
  }

  @override
  List<Object?> get props => [
    status,
    fullName,
    email,
    password,
    confirmPassword,
    isTermsAccepted,
    isPasswordVisible,
    isConfirmPasswordVisible,
    errorMessage,
    isValidEmail,
    isValidPassword,
    doPasswordsMatch,
  ];
}
