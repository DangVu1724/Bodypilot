import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/routes/app_routes.dart';
import 'package:mobile/core/theme/app_theme.dart';

class AiCoachCard extends StatelessWidget {
  const AiCoachCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Title & More Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                'Chatbot',
                style: AppTheme.headlineStyle.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Main Card
          GestureDetector(
            onTap: () => context.push(AppRoutes.aiChat),
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(color: AppTheme.primary.withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 10)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28), // Round all 4 corners
                child: Stack(
                  children: [
                    // Chatbot Background Image covering entire card
                    Positioned.fill(
                      child: Image.asset(
                        'assets/images/chatbot.png',
                        fit: BoxFit.cover,
                      ),
                    ),

                    // Dark Tinted Gradient Overlay for Text Readability
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.black.withOpacity(0.75),
                              Colors.black.withOpacity(0.35),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Overlay Content
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Top Badges
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.22),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'Tra cứu calo',
                                  style: AppTheme.semiboldStyle.copyWith(color: Colors.white, fontSize: 11),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.22),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'Tư vấn bài tập',
                                  style: AppTheme.semiboldStyle.copyWith(color: Colors.white, fontSize: 11),
                                ),
                              ),
                            ],
                          ),

                          // Bottom Row: Stats Text & Floating Chat Button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Trợ Lý BodyPilot',
                                    style: AppTheme.headlineStyle.copyWith(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      height: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Thực đơn & bài tập cá nhân hóa',
                                    style: AppTheme.bodyStyle.copyWith(
                                      color: Colors.white.withOpacity(0.95),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),

                              // Floating White Chat Button
                              Container(
                                width: 58,
                                height: 58,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(Icons.chat_bubble_rounded, color: AppTheme.primary, size: 26),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
