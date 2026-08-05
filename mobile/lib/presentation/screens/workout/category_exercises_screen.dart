import 'package:core_shared/models/exercise_model.dart';
import 'package:core_shared/models/workout_category_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/presentation/widgets/smooth_loading_overlay.dart';

import '../../../data/repositories/exercise_repository.dart';
import '../../bloc/workout/exercise_cubit.dart';
import '../../bloc/workout/exercise_state.dart';
import 'widgets/workout_skeleton.dart';
import 'exercise_detail_screen.dart';

class CategoryExercisesScreen extends StatefulWidget {
  final WorkoutCategoryModel category;

  const CategoryExercisesScreen({super.key, required this.category});

  @override
  State<CategoryExercisesScreen> createState() => _CategoryExercisesScreenState();
}

class _CategoryExercisesScreenState extends State<CategoryExercisesScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
      final cubit = context.read<ExerciseCubit>();
      cubit.loadMoreExercises(widget.category.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ExerciseCubit(ExerciseRepository())..fetchExercisesByCategory(widget.category.id),
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: RefreshIndicator(
              onRefresh: () async {
                await context.read<ExerciseCubit>().fetchExercisesByCategory(widget.category.id, forceRefresh: true);
              },
              child: NotificationListener<ScrollNotification>(
                onNotification: (scrollInfo) {
                  if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 300) {
                    context.read<ExerciseCubit>().loadMoreExercises(widget.category.id);
                  }
                  return false;
                },
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  slivers: [_buildHeader(context), _buildExerciseList()],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 250.0,
      pinned: true,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: Colors.white.withOpacity(0.3),
          child: IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?q=80&w=2070&auto=format&fit=crop',
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.3), Colors.black.withOpacity(0.8)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.fitness_center, color: Colors.white, size: 28),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.category.name.isNotEmpty ? widget.category.name : widget.category.code,
                          style: AppTheme.headlineStyle.copyWith(color: Colors.white, fontSize: 24),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      BlocBuilder<ExerciseCubit, ExerciseState>(
                        builder: (context, state) {
                          int total = 0;
                          if (state is ExerciseLoaded) {
                            total = state.totalElements;
                          }
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white.withOpacity(0.5)),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$total Bài tập',
                              style: AppTheme.bodyStyle.copyWith(color: Colors.white, fontSize: 12),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.category.description ??
                        'Build your muscles bigger & stronger with this exercise. Train everyday to get bulk!',
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseList() {
    return SliverToBoxAdapter(
      child: Transform.translate(
        offset: const Offset(0, -20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('All Workouts', style: AppTheme.headlineStyle.copyWith(fontSize: 18)),
                  Row(
                    children: [
                      Text('Infinite Scroll Active', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      const SizedBox(width: 4),
                      Icon(Icons.bolt, color: Colors.orange[400], size: 16),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              BlocBuilder<ExerciseCubit, ExerciseState>(
                builder: (context, state) {
                  if (state is ExerciseLoading) {
                    return const SmoothLoadingOverlay();
                  }
                  if (state is ExerciseLoaded) {
                    return Column(
                      children: [
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: state.exercises.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final exercise = state.exercises[index];
                            return _buildExerciseCard(context, exercise);
                          },
                        ),
                        if (state.isLoadingMore) ...[
                          const SizedBox(height: 20),
                          const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary)),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ],
                    );
                  }
                  if (state is ExerciseError) {
                    return Center(child: Text(state.message));
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseCard(BuildContext context, ExerciseModel exercise) {
    return InkWell(
      onTap: () => Navigator.of(context, rootNavigator: true)
          .push(MaterialPageRoute(builder: (context) => ExerciseDetailScreen(exercise: exercise))),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                exercise.displayImageUrl,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 70,
                  height: 70,
                  color: Colors.grey[200],
                  child: const Icon(Icons.fitness_center, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: AppTheme.semiboldStyle.copyWith(fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${exercise.bodyPart?.name ?? exercise.code} • ${exercise.equipment?.join(", ") ?? "Bodyweight"}',
                    style: AppTheme.bodyStyle.copyWith(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
