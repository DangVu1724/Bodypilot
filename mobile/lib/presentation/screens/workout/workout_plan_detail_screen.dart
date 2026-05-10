import 'package:flutter/material.dart';
import 'package:core_shared/models/workout_plan_model.dart';
import 'package:core_shared/models/workout_session_model.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'workout_session_detail_screen.dart';

class WorkoutPlanDetailScreen extends StatefulWidget {
  final WorkoutPlanModel plan;

  const WorkoutPlanDetailScreen({super.key, required this.plan});

  @override
  State<WorkoutPlanDetailScreen> createState() => _WorkoutPlanDetailScreenState();
}

class _WorkoutPlanDetailScreenState extends State<WorkoutPlanDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final totalSessions = plan.sessions?.length ?? 0;
    final totalExercises = plan.sessions?.fold<int>(0, (sum, session) => sum + (session.exercises?.length ?? 0)) ?? 0;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(context),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Transform.translate(
                    offset: const Offset(0, -40),
                    child: _buildOverviewCard(totalSessions: totalSessions, totalExercises: totalExercises),
                  ),

                  const SizedBox(height: 8),

                  Text('Workout Schedule', style: AppTheme.headlineStyle.copyWith(fontSize: 22)),

                  const SizedBox(height: 6),

                  Text(
                    'Structured training sessions crafted for your progress.',
                    style: AppTheme.bodyStyle.copyWith(color: AppTheme.textSecondary),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final session = plan.sessions?[index];

                if (session == null) {
                  return const SizedBox.shrink();
                }

                final isLast = index == (plan.sessions?.length ?? 0) - 1;

                return _buildSessionTimelineCard(context, session, isLast);
              }, childCount: plan.sessions?.length ?? 0),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final scrollOffset = constraints.scrollOffset;
        final expandedHeight = 340.0;
        final collapsedHeight = MediaQuery.of(context).padding.top + kToolbarHeight;
        
        // Fully collapsed when scrollOffset reaches expandedHeight - collapsedHeight
        final isCollapsed = scrollOffset > (expandedHeight - collapsedHeight - 20);
        final contentColor = isCollapsed ? AppTheme.textPrimary : Colors.white;

        return SliverAppBar(
          expandedHeight: expandedHeight,
          pinned: true,
          elevation: 0,
          backgroundColor: AppTheme.surface,
          iconTheme: IconThemeData(color: contentColor),
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.parallax,
            titlePadding: const EdgeInsets.only(left: 56, bottom: 16, right: 20),
            title: Text(
              widget.plan.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.headlineStyle.copyWith(color: contentColor, fontSize: 18),
            ),
            background: Stack(
              fit: StackFit.expand,
              children: [
                if (widget.plan.thumbnailUrl != null)
                  Hero(
                    tag: widget.plan.id ?? widget.plan.title,
                    child: Image.network(widget.plan.thumbnailUrl!, fit: BoxFit.cover),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primary.withOpacity(0.8), AppTheme.primary.withOpacity(0.4)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black.withOpacity(0.15), Colors.black.withOpacity(0.85)],
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 90,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isCollapsed ? 0 : 1,
                    child: Row(
                      children: [
                        _buildTag(Icons.fitness_center_rounded, widget.plan.difficulty, Colors.blueAccent),
                        const SizedBox(width: 12),
                        _buildTag(Icons.local_fire_department_rounded, widget.plan.goal, Colors.orangeAccent),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverviewCard({required int totalSessions, required int totalExercises}) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 24, offset: const Offset(0, 12))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Plan Overview', style: AppTheme.headlineStyle.copyWith(fontSize: 20)),

          const SizedBox(height: 10),

          Text(
            'A ${widget.plan.totalDays}-day fitness roadmap built to improve your ${widget.plan.goal.toLowerCase()} journey with consistent progression.',
            style: AppTheme.bodyStyle.copyWith(color: AppTheme.textSecondary, height: 1.5),
          ),

          const SizedBox(height: 22),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.calendar_month_rounded,
                  title: 'Days',
                  value: '${widget.plan.totalDays}',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.sports_gymnastics_rounded,
                  title: 'Sessions',
                  value: '$totalSessions',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildStatCard(icon: Icons.flash_on_rounded, title: 'Exercises', value: '$totalExercises'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({required IconData icon, required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 22),
          ),

          const SizedBox(height: 12),

          Text(value, style: AppTheme.headlineStyle.copyWith(fontSize: 20)),

          const SizedBox(height: 4),

          Text(title, style: AppTheme.bodyStyle.copyWith(color: AppTheme.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildTag(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),

          const SizedBox(width: 8),

          Text(label, style: AppTheme.semiboldStyle.copyWith(color: Colors.white, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildSessionTimelineCard(BuildContext context, WorkoutSessionModel session, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primary,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.35), blurRadius: 10)],
                ),
              ),

              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: AppTheme.primary.withOpacity(0.15),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 16),

          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.of(
                  context,
                  rootNavigator: true,
                ).push(MaterialPageRoute(builder: (context) => WorkoutSessionDetailScreen(session: session)));
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 22),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 8)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          colors: [AppTheme.primary, AppTheme.primary.withOpacity(0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${session.dayNumber}',
                          style: AppTheme.headlineStyle.copyWith(color: Colors.white, fontSize: 22),
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Day ${session.dayNumber}',
                            style: AppTheme.bodyStyle.copyWith(color: AppTheme.textSecondary, fontSize: 13),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            session.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.semiboldStyle.copyWith(fontSize: 17),
                          ),

                          const SizedBox(height: 10),

                          Row(
                            children: [
                              Icon(Icons.fitness_center, size: 16, color: AppTheme.textSecondary),

                              const SizedBox(width: 6),

                              Text(
                                '${session.exercises?.length ?? 0} exercises',
                                style: AppTheme.bodyStyle.copyWith(color: AppTheme.textSecondary, fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: AppTheme.primary),
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
