import 'package:flutter/material.dart';

class AiSuggestionBanner extends StatelessWidget {
  const AiSuggestionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.smart_toy, color: Colors.blue[600], size: 20),
          const SizedBox(width: 8),
          Text(
            'You have 12 AI workout suggestions.',
            style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
