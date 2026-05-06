import 'package:flutter/material.dart';
import 'package:core_shared/core_shared.dart';
import '../../core/theme.dart';
import '../../data/repositories/admin_repository.dart';

class ExerciseDetailScreen extends StatefulWidget {
  final String exerciseId;

  const ExerciseDetailScreen({super.key, required this.exerciseId});

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  late Future<ExerciseModel> _exerciseFuture;

  @override
  void initState() {
    super.initState();
    _exerciseFuture = adminRepository.getExerciseById(widget.exerciseId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Chi tiết bài tập', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        actions: [
          _buildActionButton(Icons.edit_outlined, 'Sửa', AppTheme.primaryColor),
          const SizedBox(width: 12),
          _buildActionButton(Icons.delete_outline, 'Xóa', Colors.red),
          const SizedBox(width: 24),
        ],
      ),
      body: FutureBuilder<ExerciseModel>(
        future: _exerciseFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          final exercise = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // BÊN TRÁI: Hình ảnh
                    Expanded(
                      flex: 2,
                      child: _buildImageCard(exercise),
                    ),
                    const SizedBox(width: 24),
                    // BÊN PHẢI: Thông tin chi tiết
                    Expanded(
                      flex: 3,
                      child: _buildDetailsCard(exercise),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildInstructionsSection(exercise),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color) {
    return TextButton.icon(
      onPressed: () {},
      icon: Icon(icon, color: color, size: 20),
      label: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      style: TextButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildImageCard(ExerciseModel exercise) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Hình ảnh bài tập', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: exercise.thumbnailUrl != null
                  ? Image.network(
                      exercise.thumbnailUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.blue.shade50,
                        child: const Icon(Icons.broken_image_outlined, size: 64, color: Colors.blue),
                      ),
                    )
                  : Container(
                      color: Colors.grey.shade100,
                      child: const Icon(Icons.fitness_center_outlined, size: 64, color: Colors.grey),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(ExerciseModel exercise) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Thông tin chung', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text(exercise.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          const Text('Mô tả bài tập', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(
            exercise.description ?? 'Không có mô tả cho bài tập này.',
            style: const TextStyle(fontSize: 16, height: 1.6, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 32,
            runSpacing: 24,
            children: [
              _buildMetaItem('Hạng mục', exercise.category?.name ?? 'General', AppTheme.primaryColor),
              _buildMetaItem('Độ khó', exercise.difficulty ?? 'N/A', Colors.orange),
              _buildMetaItem('METs', '${exercise.metValue ?? 0}', Colors.blue),
              _buildMetaItem('Mã bài tập', exercise.code, Colors.grey),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        ),
      ],
    );
  }

  Widget _buildInstructionsSection(ExerciseModel exercise) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Chi tiết mục tiêu & Video', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Cơ mục tiêu chính', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                    const SizedBox(height: 8),
                    _buildMuscleChip(exercise.targetMuscle?.name ?? 'N/A', Colors.orange),
                    const SizedBox(height: 24),
                    const Text('Vùng cơ thể', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                    const SizedBox(height: 8),
                    _buildMuscleChip(exercise.bodyPart?.name ?? 'N/A', Colors.blue),
                  ],
                ),
              ),
              const SizedBox(width: 48),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Video hướng dẫn', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                    const SizedBox(height: 12),
                    if (exercise.mediaUrl != null)
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)),
                        child: const Center(child: Icon(Icons.play_circle_fill, size: 64, color: Colors.white70)),
                      )
                    else
                      const Text('Không có video hướng dẫn.'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMuscleChip(String name, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.2))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.adjust, color: color, size: 16),
          const SizedBox(width: 8),
          Text(name, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
