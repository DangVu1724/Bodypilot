import 'package:flutter/material.dart';
import 'package:mobile/core/routes/app_routes.dart';

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
                const Text(
                  'Welcome to BodyPilot',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 10),
                const Text('Your personal fitness AI Assistant', style: TextStyle(fontSize: 16, color: Colors.white)),
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
                    const Text('Already have an account?', style: TextStyle(color: Colors.white)),
                    const SizedBox(width: 5),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, AppRoutes.login);
                      },
                      child: const Text(
                        'Login',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
