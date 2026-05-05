import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/routes/app_routes.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/presentation/bloc/auth/login_cubit.dart';
import 'package:mobile/presentation/bloc/auth/login_state.dart';
import 'package:mobile/presentation/bloc/user/user_cubit.dart';
import 'package:mobile/presentation/bloc/food/food_cubit.dart';
import 'package:mobile/presentation/widgets/black_button_2.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => LoginCubit(), child: const LoginView());
  }
}

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginCubit, LoginState>(
      listener: (context, state) {
        if (state.status == LoginStatus.success) {
          // Fetch data immediately after successful login
          context.read<UserCubit>().fetchUserProfile();
          context.read<FoodCubit>().init();
          
          if (state.isProfileComplete == true) {
            Navigator.pushReplacementNamed(context, AppRoutes.home);
          } else {
            Navigator.pushReplacementNamed(context, AppRoutes.assessment);
          }
        } else if (state.status == LoginStatus.failure) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.errorMessage ?? 'Login failed'), backgroundColor: Colors.red));
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: BlocBuilder<LoginCubit, LoginState>(
              builder: (context, state) {
                final cubit = context.read<LoginCubit>();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 60),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
                      child: Icon(Icons.fitness_center, size: 50, color: Colors.blue.shade700),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      'Welcome Back',
                      style: AppTheme.headlineStyle.copyWith(fontSize: 28),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to continue',
                      style: AppTheme.bodyStyle.copyWith(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 40),
                    TextField(
                      onChanged: cubit.emailChanged,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        hintText: 'you@example.com',
                        prefixIcon: const Icon(Icons.email_outlined),
                        errorText: state.email.isNotEmpty && !state.isValidEmail ? 'Enter a valid email' : null,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.primary, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      onChanged: cubit.passwordChanged,
                      obscureText: !state.isPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Enter your password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            state.isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          ),
                          onPressed: cubit.togglePasswordVisibility,
                        ),
                        errorText: state.password.isNotEmpty && !state.isValidPassword
                            ? 'Password must be at least 6 characters'
                            : null,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.primary, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: Text('Forgot Password?', style: AppTheme.bodyStyle.copyWith(color: AppTheme.primary)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // BlackButton(
                    //   label: state.status == LoginStatus.loading ? 'Signing in...' : 'Sign In',
                    //   onPressed: state.status == LoginStatus.loading ? null : cubit.submit,
                    //   borderRadius: 12,
                    //   padding: const EdgeInsets.symmetric(vertical: 16),
                    // ),
                    BlackButton2(
                      label: state.status == LoginStatus.loading ? 'Signing in...' : 'Sign In',
                      onPressed: state.status == LoginStatus.loading ? null : cubit.submit,
                      borderRadius: 12,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text('Or', style: AppTheme.bodyStyle.copyWith(color: Colors.grey.shade600)),
                        ),
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: Icon(Icons.g_mobiledata, color: Colors.red.shade700),
                            label: const Text('Google'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: Icon(Icons.facebook, color: Colors.blue.shade800),
                            label: const Text('Facebook'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Don't have an account? ", style: AppTheme.bodyStyle.copyWith(color: Colors.grey.shade600)),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, AppRoutes.signup);
                          },
                          child: Text(
                            'Sign Up',
                            style: AppTheme.semiboldStyle.copyWith(color: AppTheme.primary),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
