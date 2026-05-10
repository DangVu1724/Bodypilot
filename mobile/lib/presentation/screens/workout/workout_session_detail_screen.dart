import 'package:flutter/material.dart';
import 'package:core_shared/models/workout_session_model.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'exercise_detail_screen.dart';

class WorkoutSessionDetailScreen extends StatelessWidget {
  final WorkoutSessionModel session;

  const WorkoutSessionDetailScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    // Calculate total duration
    int totalDuration = 0;
    if (session.exercises != null) {
      for (var ex in session.exercises!) {
        totalDuration += ex.durationMinutes ?? 0;
      }
    }
    
    // Fallback if duration is 0
    if (totalDuration == 0) totalDuration = 45; 

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 400,
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage('https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800&q=80'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.4),
                      Colors.black.withOpacity(0.1),
                      Colors.white,
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
              ),
            ),
          ),
          
          // Content
          CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 120),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.5)),
                        ),
                        child: Text(
                          'Day ${session.dayNumber}',
                          style: AppTheme.semiboldStyle.copyWith(color: Colors.white, fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        session.name,
                        style: AppTheme.headlineStyle.copyWith(color: Colors.white, fontSize: 32),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'With BodyPilot Expert',
                        style: AppTheme.bodyStyle.copyWith(color: Colors.white.withOpacity(0.8)),
                      ),
                      const SizedBox(height: 40),
                      
                      // White rounded container starts here
                      Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 32),
                            Text(
                              'Prepare to transform your muscles with our targeted and effective workout routine tailored for you.',
                              textAlign: TextAlign.center,
                              style: AppTheme.bodyStyle.copyWith(color: AppTheme.textSecondary),
                            ),
                            const SizedBox(height: 32),
                            
                            // Stats row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatItem(Icons.access_time, '${totalDuration}min', 'Time'),
                                _buildStatItem(Icons.local_fire_department, '${totalDuration * 5}kcal', 'Calorie'),
                                _buildStatItem(Icons.fitness_center, '${session.exercises?.length ?? 0}x4', 'Sets'),
                              ],
                            ),
                            const SizedBox(height: 40),
                            
                            // Exercise List
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: session.exercises?.length ?? 0,
                              itemBuilder: (context, index) {
                                  final ex = session.exercises![index];
                                return _buildExerciseItem(context, ex, index + 1);
                              },
                            ),
                            const SizedBox(height: 100), // Space for bottom button
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // Bottom Button
          Positioned(
            bottom: 30,
            left: 24,
            right: 24,
            child: ElevatedButton(
              onPressed: () {
                // TODO: Start workout flow
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Start Workout',
                    style: AppTheme.semiboldStyle.copyWith(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.timer_outlined, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.textSecondary, size: 20),
        const SizedBox(height: 8),
        Text(value, style: AppTheme.semiboldStyle.copyWith(fontSize: 16)),
        const SizedBox(height: 2),
        Text(label, style: AppTheme.bodyStyle.copyWith(color: AppTheme.textSecondary, fontSize: 12)),
      ],
    );
  }

  Widget _buildExerciseItem(BuildContext context, dynamic ex, int number) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
            builder: (context) => ExerciseDetailScreen(exercise: ex.exercise),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            // Thumbnail with play button
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: DecorationImage(
                      image: NetworkImage(ex.exercise.thumbnailUrl ?? 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=200&q=80'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow, color: Colors.white, size: 20),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Exercise $number',
                      style: AppTheme.semiboldStyle.copyWith(color: AppTheme.textSecondary, fontSize: 10),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ex.exercise.name,
                    style: AppTheme.semiboldStyle.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 14, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${ex.durationMinutes ?? 10}:00',
                        style: AppTheme.bodyStyle.copyWith(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
