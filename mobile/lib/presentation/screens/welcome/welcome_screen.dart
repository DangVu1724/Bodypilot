import 'package:flutter/material.dart';
import 'package:mobile/core/routes/app_routes.dart';
import 'package:mobile/core/theme/app_theme.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Ảnh nền
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(image: AssetImage('assets/images/yoga.png'), fit: BoxFit.cover),
            ),
          ),
          Container(color: const Color(0x80000000)),
          // Nội dung
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Text(
                  'Welcome to BodyPilot',
                  style: AppTheme.headlineStyle.copyWith(fontSize: 24, color: Colors.white),
                ),
                const SizedBox(height: 10),
                Text('Your personal fitness AI Assistant', style: AppTheme.bodyStyle.copyWith(fontSize: 16, color: Colors.white)),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.onboarding);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF97316),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                  child: const Text('Get Started'),
                ),

                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Already have an account?', style: AppTheme.bodyStyle.copyWith(color: Colors.white)),
                    const SizedBox(width: 5),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, AppRoutes.login);
                      },
                      child:  Text(
                        'Login',
                        style: AppTheme.semiboldStyle.copyWith(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
