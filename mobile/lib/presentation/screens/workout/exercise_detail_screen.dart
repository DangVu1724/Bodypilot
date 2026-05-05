import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/exercise_model.dart';
import 'exercise_timer_screen.dart';

class ExerciseDetailScreen extends StatefulWidget {
  final ExerciseModel exercise;

  const ExerciseDetailScreen({super.key, required this.exercise});

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  late YoutubePlayerController _controller;
  bool _isPlayerReady = false;

  @override
  void initState() {
    super.initState();
    final videoId = YoutubePlayer.convertUrlToId(widget.exercise.mediaUrl ?? '') ?? '';
    _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(autoPlay: false, mute: false, isLive: false),
    )..addListener(_listener);
  }

  void _listener() {
    if (_isPlayerReady && mounted && !_controller.value.isFullScreen) {
      setState(() {});
    }
  }

  @override
  void deactivate() {
    _controller.pause();
    super.deactivate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(
              builder: (context) => ExerciseTimerScreen(exercise: widget.exercise),
            ),
          );
        },
        backgroundColor: AppTheme.primary,
        elevation: 4,
        highlightElevation: 8,
        label: Row(
          children: [
            Text('Start Exercise', style: AppTheme.semiboldStyle.copyWith(color: Colors.white)),
            const SizedBox(width: 8),
            const Icon(Icons.play_arrow_rounded, color: Colors.white),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildMuscleSection(),
                  const SizedBox(height: 24),
                  _buildEquipmentSection(),
                  const SizedBox(height: 24),
                  _buildDescriptionSection(),
                  const SizedBox(height: 32),
                  _buildVideoSection(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: Colors.black,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: Colors.white.withOpacity(0.3),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              widget.exercise.thumbnailUrl ?? 'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=800&q=80',
              fit: BoxFit.cover,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black54, Colors.transparent, Colors.transparent, Colors.black87],
                  stops: [0.0, 0.2, 0.8, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(widget.exercise.name, style: AppTheme.headlineStyle.copyWith(fontSize: 28))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.exercise.difficulty ?? 'Intermediate',
                style: AppTheme.semiboldStyle.copyWith(color: AppTheme.primary, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildInfoChip(Icons.fitness_center, widget.exercise.category?.name ?? 'General'),
            const SizedBox(width: 12),
            _buildInfoChip(Icons.local_fire_department, '${widget.exercise.metValue ?? 5.0} METs'),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        Text(label, style: AppTheme.bodyStyle.copyWith(color: Colors.grey, fontSize: 14)),
      ],
    );
  }

  Widget _buildMuscleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Muscle Targeting', style: AppTheme.headlineStyle.copyWith(fontSize: 18)),
        const SizedBox(height: 16),
        if (widget.exercise.bodyPart != null) ...[
          Text('Body Part', style: AppTheme.bodyStyle.copyWith(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          _buildDetailCard(
            title: widget.exercise.bodyPart!.name,
            subtitle: 'Main Area',
            icon: Icons.accessibility_new,
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
        ],
        if (widget.exercise.targetMuscle != null) ...[
          Text('Primary Muscle', style: AppTheme.bodyStyle.copyWith(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          _buildDetailCard(
            title: widget.exercise.targetMuscle!.name,
            subtitle: 'Target',
            icon: Icons.adjust,
            color: Colors.orange,
          ),
          const SizedBox(height: 16),
        ],
        if (widget.exercise.secondaryMuscles != null && widget.exercise.secondaryMuscles!.isNotEmpty) ...[
          Text('Secondary Muscles', style: AppTheme.bodyStyle.copyWith(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.exercise.secondaryMuscles!.map((muscle) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                child: Text(muscle.name, style: AppTheme.semiboldStyle.copyWith(fontSize: 12)),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildDetailCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTheme.semiboldStyle.copyWith(fontSize: 16)),
              Text(subtitle, style: AppTheme.bodyStyle.copyWith(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentSection() {
    if (widget.exercise.equipment == null || widget.exercise.equipment!.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Equipment Needed', style: AppTheme.headlineStyle.copyWith(fontSize: 18)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: widget.exercise.equipment!.map((e) {
            return Chip(
              label: Text(e, style: AppTheme.bodyStyle.copyWith(fontSize: 12)),
              backgroundColor: Colors.blue[50],
              side: BorderSide.none,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Instructions', style: AppTheme.headlineStyle.copyWith(fontSize: 18)),
        const SizedBox(height: 12),
        Text(
          widget.exercise.description ?? 'No instructions available for this exercise.',
          style: AppTheme.bodyStyle.copyWith(height: 1.6, color: Colors.grey[800]),
        ),
      ],
    );
  }

  Widget _buildVideoSection() {
    if (widget.exercise.mediaUrl == null || widget.exercise.mediaUrl!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.videocam_outlined, color: AppTheme.primary),
            const SizedBox(width: 8),
            Text('Video Tutorial', style: AppTheme.headlineStyle.copyWith(fontSize: 18)),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: YoutubePlayer(
              controller: _controller,
              showVideoProgressIndicator: true,
              onReady: () => _isPlayerReady = true,
            ),
          ),
        ),
      ],
    );
  }
}
