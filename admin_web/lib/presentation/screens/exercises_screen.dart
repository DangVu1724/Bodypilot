import 'package:flutter/material.dart';
import 'package:core_shared/core_shared.dart';
import '../../core/theme.dart';
import '../../data/repositories/admin_repository.dart';
import '../widgets/base_table_screen.dart';
import '../../data/models/page_response_model.dart';
import '../widgets/exercise_form_dialog.dart';
import 'exercise_detail_screen.dart';

class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({super.key});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  late Future<PageResponseModel<ExerciseModel>> _exercisesFuture;
  List<CategoryFilterItem> _categoryFilterItems = [const CategoryFilterItem(id: null, label: 'Tất cả')];
  String _searchQuery = '';
  String? _selectedCategoryId;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadExercises(page: 0);
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await adminRepository.getAllWorkoutCategories();
      if (mounted) {
        setState(() {
          _categoryFilterItems = [
            const CategoryFilterItem(id: null, label: 'Tất cả'),
            ...categories.map((c) => CategoryFilterItem(id: c.id, label: c.name)),
          ];
        });
      }
    } catch (_) {}
  }

  void _loadExercises({int page = 0}) {
    setState(() {
      _currentPage = page;
      _exercisesFuture = adminRepository.getAllExercises(
        page: page,
        size: 20,
        search: _searchQuery,
        categoryId: _selectedCategoryId,
      );
    });
  }

  void _refreshExercises() {
    _loadExercises(page: _currentPage);
  }

  void _onSearchChanged(String query) {
    _searchQuery = query;
    _loadExercises(page: 0);
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
    return FutureBuilder<PageResponseModel<ExerciseModel>>(
      future: _exercisesFuture,
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final pageData = snapshot.data ?? PageResponseModel<ExerciseModel>.empty();
        final exercises = pageData.content;

        return BaseTableScreen(
          title: 'Bài tập',
          subtitle: 'Quản lý kho bài tập (Exercises) trong hệ thống',
          onRefresh: _refreshExercises,
          onAddPressed: () => _showAddEditDialog(),
          onSearchChanged: _onSearchChanged,
          searchHint: 'Tìm theo tên bài tập...',
          categoryFilters: _categoryFilterItems,
          selectedCategoryId: _selectedCategoryId,
          onCategorySelected: (catId) {
            _selectedCategoryId = catId;
            _loadExercises(page: 0);
          },
          isLoading: isLoading,
          currentPage: pageData.pageNumber,
          totalPages: pageData.totalPages,
          totalElements: pageData.totalElements,
          pageSize: pageData.pageSize,
          onPageChanged: (newPage) => _loadExercises(page: newPage),
          columns: const ['ID', 'Tên bài tập', 'Danh mục', 'Cơ chính', 'Độ khó', 'MET', 'Thao tác'],
          rows: exercises
              .map(
                (ex) => DataRow(
                  cells: [
                    DataCell(Text(ex.id.length >= 8 ? ex.id.substring(0, 8) : ex.id)),
                    DataCell(Text(ex.name)),
                    DataCell(Text(ex.category?.name ?? 'Chưa phân loại')),
                    DataCell(Text(ex.targetMuscle?.name ?? 'Chưa rõ')),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: ex.difficulty == 'BEGINNER'
                              ? Colors.green.shade50
                              : ex.difficulty == 'INTERMEDIATE'
                                  ? Colors.orange.shade50
                                  : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          ex.difficulty ?? 'N/A',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: ex.difficulty == 'BEGINNER'
                                ? Colors.green.shade700
                                : ex.difficulty == 'INTERMEDIATE'
                                    ? Colors.orange.shade700
                                    : Colors.red.shade700,
                          ),
                        ),
                      ),
                    ),
                    DataCell(Text('${ex.metValue ?? 0}')),
                    DataCell(
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.visibility_outlined, size: 18, color: AppTheme.primaryColor),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ExerciseDetailScreen(exerciseId: ex.id)),
                            ),
                          ),
                          IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _showAddEditDialog(ex)),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                            onPressed: () => _deleteExercise(ex.id),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
        );
      },
    );
  }
}
