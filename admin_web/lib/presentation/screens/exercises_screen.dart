import 'package:flutter/material.dart';
import 'package:core_shared/core_shared.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme.dart';
import '../../data/repositories/admin_repository.dart';
import '../widgets/base_table_screen.dart';
import '../widgets/exercise_form_dialog.dart';
import 'exercise_detail_screen.dart';

class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({super.key});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  late Future<List<ExerciseModel>> _exercisesFuture;

  @override
  void initState() {
    super.initState();
    _exercisesFuture = adminRepository.getAllExercises();
  }

  void _refreshExercises() {
    setState(() {
      _exercisesFuture = adminRepository.getAllExercises(forceRefresh: true);
    });
  }

  Future<void> _showAddEditDialog([ExerciseModel? exercise]) async {
    final result = await showDialog<ExerciseModel>(
      context: context,
      builder: (context) => ExerciseFormDialog(exercise: exercise),
    );

    if (result != null) {
      try {
        if (exercise == null) {
          await adminRepository.createExercise(result);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thêm thành công')));
        } else {
          await adminRepository.updateExercise(exercise.id, result);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sửa thành công')));
        }
        _refreshExercises();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  Future<void> _deleteExercise(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa bài tập này không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await adminRepository.deleteExercise(id);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xóa thành công')));
        _refreshExercises();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi xóa: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ExerciseModel>>(
      future: _exercisesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }

        final exercises = snapshot.data ?? [];

        return BaseTableScreen(
          title: 'Bài tập',
          subtitle: 'Danh sách các bài tập workout thực tế từ hệ thống',
          onRefresh: _refreshExercises,
          onAddPressed: () => _showAddEditDialog(),
          columns: const ['Mã', 'Tên bài tập', 'Độ khó', 'Hạng mục', 'Thao tác'],
          rows: exercises.map((ex) => DataRow(cells: [
            DataCell(Text(ex.code)),
            DataCell(Text(ex.name)),
            DataCell(Text(ex.difficulty ?? 'N/A')),
            DataCell(Text(ex.category?.name ?? 'General')),
            DataCell(Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility_outlined, size: 18, color: AppTheme.primaryColor),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ExerciseDetailScreen(exerciseId: ex.id)),
                  ),
                ),
                IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _showAddEditDialog(ex)),
                IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red), onPressed: () => _deleteExercise(ex.id)),
              ],
            )),
          ])).toList(),
        );
      },
    );
  }
}
