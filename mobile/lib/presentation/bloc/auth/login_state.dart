import 'package:equatable/equatable.dart';

enum LoginStatus { initial, loading, success, failure }

class LoginState extends Equatable {
  final LoginStatus status;
  final String email;
  final String password;
  final bool isPasswordVisible;
  final String? errorMessage;
  final bool isValidEmail;
  final bool isValidPassword;
  final bool? isProfileComplete;

  const LoginState({
    this.status = LoginStatus.initial,
    this.email = '',
    this.password = '',
    this.isPasswordVisible = false,
    this.errorMessage,
    this.isValidEmail = false,
    this.isValidPassword = false,
    this.isProfileComplete,
  });

  bool get isFormValid => isValidEmail && isValidPassword;

  LoginState copyWith({
    LoginStatus? status,
    String? email,
    String? password,
    bool? isPasswordVisible,
    String? errorMessage,
    bool? isValidEmail,
    bool? isValidPassword,
    bool? isProfileComplete,
  }) {
    return LoginState(
      status: status ?? this.status,
      email: email ?? this.email,
      password: password ?? this.password,
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
      errorMessage: errorMessage ?? this.errorMessage,
      isValidEmail: isValidEmail ?? this.isValidEmail,
      isValidPassword: isValidPassword ?? this.isValidPassword,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
    );
  }

  @override
  List<Object?> get props => [
    status,
    email,
    password,
    isPasswordVisible,
    errorMessage,
    isValidEmail,
    isValidPassword,
    isProfileComplete,
  ];
}
