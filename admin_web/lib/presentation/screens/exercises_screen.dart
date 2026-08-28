import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core_shared/core_shared.dart';
import '../../core/theme.dart';
import '../../data/repositories/admin_repository.dart';
import '../../logic/cubits/exercises/exercises_cubit.dart';
import '../../logic/cubits/exercises/exercises_state.dart';
import '../widgets/base_table_screen.dart';
import '../widgets/exercise_form_dialog.dart';
import 'exercise_detail_screen.dart';

class ExercisesScreen extends StatelessWidget {
  const ExercisesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ExercisesCubit(adminRepository: adminRepository)..fetchExercises(),
      child: const _ExercisesScreenContent(),
    );
  }
}

class _ExercisesScreenContent extends StatefulWidget {
  const _ExercisesScreenContent();

  @override
  State<_ExercisesScreenContent> createState() => _ExercisesScreenContentState();
}

class _ExercisesScreenContentState extends State<_ExercisesScreenContent> {
  List<CategoryFilterItem> _categoryFilterItems = [const CategoryFilterItem(id: null, label: 'Tất cả')];
  String? _selectedCategoryId;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCategories();
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

  void _showAddExerciseDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const ExerciseFormDialog(),
    );
    if (result == true && mounted) {
      context.read<ExercisesCubit>().fetchExercises(search: _searchQuery, categoryId: _selectedCategoryId);
    }
  }

  void _showEditExerciseDialog(BuildContext context, ExerciseModel exercise) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ExerciseFormDialog(exercise: exercise),
    );
    if (result == true && mounted) {
      context.read<ExercisesCubit>().fetchExercises(search: _searchQuery, categoryId: _selectedCategoryId);
    }
  }

  void _confirmDeleteExercise(BuildContext context, ExerciseModel exercise) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa bài tập "${exercise.name}" không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await context.read<ExercisesCubit>().deleteExercise(exercise.id);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Xóa bài tập thành công!')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExercisesCubit, ExercisesState>(
      builder: (context, state) {
        final isLoading = state is ExercisesLoading;
        final pageData = state is ExercisesSuccess ? state.pageData : null;
        final items = pageData?.content ?? [];

        return BaseTableScreen(
          title: 'Quản lý Bài tập',
          subtitle: 'Danh sách bài tập và phân loại nhóm cơ',
          searchHint: 'Tìm kiếm tên bài tập...',
          categoryFilters: _categoryFilterItems,
          selectedCategoryId: _selectedCategoryId,
          onCategorySelected: (catId) {
            setState(() {
              _selectedCategoryId = catId;
            });
            context.read<ExercisesCubit>().fetchExercises(search: _searchQuery, categoryId: catId);
          },
          onSearchChanged: (query) {
            _searchQuery = query;
            context.read<ExercisesCubit>().fetchExercises(search: query, categoryId: _selectedCategoryId);
          },
          onRefresh: () => context.read<ExercisesCubit>().fetchExercises(search: _searchQuery, categoryId: _selectedCategoryId),
          onAddPressed: () => _showAddExerciseDialog(context),
          currentPage: pageData?.pageNumber ?? 0,
          totalPages: pageData?.totalPages ?? 1,
          totalElements: pageData?.totalElements ?? 0,
          pageSize: pageData?.pageSize ?? 20,
          onPageChanged: (newPage) {
            context.read<ExercisesCubit>().fetchExercises(
                  page: newPage,
                  search: _searchQuery,
                  categoryId: _selectedCategoryId,
                );
          },
          isLoading: isLoading,
          columns: const [
            'Tên Bài tập',
            'Loại',
            'Nhóm cơ',
            'Độ khó',
            'Chỉ số MET',
            'Hành động',
          ],
          rows: items.map((exercise) {
            return DataRow(
              cells: [
                DataCell(
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          exercise.displayImageUrl,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 44,
                            height: 44,
                            color: const Color(0xFFF1F5F9),
                            child: const Icon(Icons.fitness_center, size: 22, color: AppTheme.textSecondary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          exercise.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                ),
                DataCell(Text(exercise.category?.name ?? '---', style: const TextStyle(fontSize: 14))),
                DataCell(Text(exercise.bodyPart?.name ?? '---', style: const TextStyle(fontSize: 14))),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      exercise.difficulty ?? '---',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                    ),
                  ),
                ),
                DataCell(Text('${exercise.metValue ?? 0} MET', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
                DataCell(
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility_outlined, size: 20, color: AppTheme.textSecondary),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ExerciseDetailScreen(exerciseId: exercise.id),
                            ),
                          );
                        },
                        tooltip: 'Xem chi tiết',
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20, color: AppTheme.textSecondary),
                        onPressed: () => _showEditExerciseDialog(context, exercise),
                        tooltip: 'Chỉnh sửa',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                        onPressed: () => _confirmDeleteExercise(context, exercise),
                        tooltip: 'Xóa',
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        );
      },
    );
  }
}
