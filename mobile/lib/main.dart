import 'package:flutter/material.dart';
import 'package:mobile/core/routes/app_pages.dart';
import 'package:mobile/core/routes/app_routes.dart';
import 'package:mobile/core/theme/app_theme.dart';

void main() {
  runApp(const BodyPilotApp());
}

class BodyPilotApp extends StatelessWidget {
  const BodyPilotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BodyPilot',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppPages.onGenerateRoute,
    );
  }
}
