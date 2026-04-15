import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BodyPilot Home'), elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Today', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Text('Track your workout, progress, and goals from a clean dashboard.'),
          ],
        ),
      ),
    );
  }
}
