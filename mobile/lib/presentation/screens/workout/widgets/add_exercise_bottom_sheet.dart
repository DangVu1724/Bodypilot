import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core_shared/models/exercise_model.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/presentation/bloc/workout/workout_category_cubit.dart';
import 'package:mobile/presentation/bloc/workout/workout_category_state.dart';
import 'package:mobile/presentation/bloc/workout/workout_diary_cubit.dart';
import 'package:mobile/data/repositories/exercise_repository.dart';

class AddExerciseBottomSheet extends StatefulWidget {
  final DateTime selectedDate;

  const AddExerciseBottomSheet({
    super.key,
    required this.selectedDate,
  });

  @override
  State<AddExerciseBottomSheet> createState() => _AddExerciseBottomSheetState();
}

class _AddExerciseBottomSheetState extends State<AddExerciseBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategoryId;

  List<ExerciseModel> _searchResults = [];
  bool _isLoading = false;

  ExerciseModel? _selectedExercise;
  
  // Custom exercise mode
  bool _isCustomMode = false;
  final TextEditingController _customNameController = TextEditingController();

  // Exercise stats form
  int _sets = 3;
  int _reps = 12;
  double _weight = 0.0;
  int _duration = 10;
  int _rest = 60;
  double _distance = 0.0;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchExercises();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _customNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _searchExercises() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await exerciseRepository.searchExercises(
        name: _searchQuery.isNotEmpty ? _searchQuery : null,
        categoryId: _selectedCategoryId,
        size: 20,
      );
      setState(() {
        _searchResults = response.content;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
    }
  }

  Widget _buildCategoryFilters() {
    return BlocBuilder<WorkoutCategoryCubit, WorkoutCategoryState>(
      builder: (context, state) {
        if (state is! WorkoutCategoryLoaded) {
          return const SizedBox(height: 38);
        }

        final categories = state.categories;

        return SizedBox(
          height: 38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: categories.length + 1,
            itemBuilder: (context, index) {
              final isAll = index == 0;
              final category = isAll ? null : categories[index - 1];
              final isSelected = _selectedCategoryId == category?.id;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategoryId = category?.id;
                  });
                  _searchExercises();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primary : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppTheme.primary : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    isAll ? 'All' : category!.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Drag handle and Title
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedExercise != null || _isCustomMode
                      ? 'Configure Exercise'
                      : 'Add Exercise',
                  style: AppTheme.headlineStyle.copyWith(
                    fontSize: 22,
                    color: AppTheme.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (_selectedExercise == null && !_isCustomMode) ...[
            // Search Field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                  _searchExercises();
                },
                decoration: InputDecoration(
                  hintText: 'Search exercises...',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppTheme.textSecondary,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                            _searchExercises();
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.grey[100]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: AppTheme.primary),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildCategoryFilters(),
            const SizedBox(height: 16),
          ],

          // Main body
          Expanded(
            child: _selectedExercise == null && !_isCustomMode
                ? _buildExerciseList()
                : _buildConfigureForm(),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      children: [
        // Custom exercise button
        Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.primary, width: 1.5),
          ),
          elevation: 0,
          color: AppTheme.primary.withOpacity(0.05),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: AppTheme.primary.withOpacity(0.2),
              child: const Icon(Icons.edit, color: AppTheme.primary),
            ),
            title: Text(
              'Add Custom Exercise',
              style: AppTheme.semiboldStyle.copyWith(fontSize: 15, color: AppTheme.primary),
            ),
            subtitle: Text(
              'Enter name and details manually',
              style: AppTheme.bodyStyle.copyWith(fontSize: 13, color: AppTheme.textSecondary),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.primary),
            onTap: () {
              setState(() {
                _isCustomMode = true;
                _customNameController.text = _searchQuery;
              });
            },
          ),
        ),

        ..._searchResults.map((exercise) {
          final isCardio = exercise.category?.code.toLowerCase() == 'cardio';
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
            color: Colors.grey[50],
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: exercise.thumbnailUrl != null && exercise.thumbnailUrl!.isNotEmpty
                    ? Image.network(
                        exercise.thumbnailUrl!,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          width: 50,
                          height: 50,
                          color: Colors.grey[200],
                          child: const Icon(Icons.fitness_center, color: Colors.grey),
                        ),
                      )
                    : Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey[200],
                        child: const Icon(Icons.fitness_center, color: Colors.grey),
                      ),
              ),
              title: Text(
                exercise.name,
                style: AppTheme.semiboldStyle.copyWith(fontSize: 15),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${exercise.difficulty ?? 'Medium'} • ${exercise.targetMuscle?.name ?? 'Muscle'}',
                style: AppTheme.bodyStyle.copyWith(fontSize: 13, color: AppTheme.textSecondary),
              ),
              trailing: Container(
                decoration: BoxDecoration(
                  color: isCardio ? Colors.blue.withOpacity(0.1) : AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add,
                      size: 16,
                      color: isCardio ? Colors.blue[800] : AppTheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isCardio ? 'Cardio' : 'Add',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isCardio ? Colors.blue[800] : AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              onTap: () {
                setState(() {
                  _selectedExercise = exercise;
                  _duration = exercise.defaultDuration != null ? exercise.defaultDuration!.round() : 10;
                  _sets = isCardio ? 1 : 3;
                  _reps = isCardio ? 0 : 12;
                });
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildConfigureForm() {
    final name = _selectedExercise != null ? _selectedExercise!.name : 'Custom Exercise';
    final isCardio = _selectedExercise != null 
        ? _selectedExercise!.category?.code.toLowerCase() == 'cardio'
        : false;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header preview
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _selectedExercise = null;
                    _isCustomMode = false;
                  });
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isCustomMode ? 'Custom Workout' : name,
                      style: AppTheme.headlineStyle.copyWith(fontSize: 18),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _isCustomMode 
                          ? 'Manual Exercise log' 
                          : '${_selectedExercise!.difficulty ?? 'Medium'} • MET: ${_selectedExercise!.metValue ?? 3.0}',
                      style: AppTheme.bodyStyle.copyWith(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (_isCustomMode) ...[
            Text('Exercise Name', style: AppTheme.semiboldStyle.copyWith(fontSize: 15)),
            const SizedBox(height: 8),
            TextField(
              controller: _customNameController,
              decoration: InputDecoration(
                hintText: 'e.g., Pull ups, Jogging',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Form fields (Sets, Reps, Weight or Duration, Distance)
          if (!isCardio) ...[
            Row(
              children: [
                Expanded(
                  child: _buildNumberSpinner(
                    label: 'Sets',
                    value: _sets,
                    onChanged: (val) => setState(() => _sets = val),
                    min: 1,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildNumberSpinner(
                    label: 'Reps',
                    value: _reps,
                    onChanged: (val) => setState(() => _reps = val),
                    min: 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildDoubleSpinner(
              label: 'Weight (kg)',
              value: _weight,
              onChanged: (val) => setState(() => _weight = val),
              step: 2.5,
              suffix: 'kg',
            ),
            const SizedBox(height: 20),
            _buildNumberSpinner(
              label: 'Rest Time (seconds)',
              value: _rest,
              onChanged: (val) => setState(() => _rest = val),
              min: 0,
              step: 15,
              suffix: 's',
            ),
            const SizedBox(height: 20),
          ],

          Row(
            children: [
              Expanded(
                child: _buildNumberSpinner(
                  label: 'Duration (minutes)',
                  value: _duration,
                  onChanged: (val) => setState(() => _duration = val),
                  min: 1,
                  step: 5,
                  suffix: 'm',
                ),
              ),
              if (isCardio || _isCustomMode) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDoubleSpinner(
                    label: 'Distance (km)',
                    value: _distance,
                    onChanged: (val) => setState(() => _distance = val),
                    step: 0.5,
                    suffix: 'km',
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),

          // Notes field
          Text('Notes / Tips', style: AppTheme.semiboldStyle.copyWith(fontSize: 15)),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'e.g., Focus on slow reps',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 32),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final exerciseName = _isCustomMode 
                    ? _customNameController.text.trim()
                    : name;

                if (exerciseName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter exercise name'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final itemData = {
                  'exerciseId': _selectedExercise?.id,
                  'orderIndex': 0,
                  'isCompleted': false,
                  'exerciseName': exerciseName,
                  'sets': isCardio ? null : _sets,
                  'reps': isCardio ? null : _reps,
                  'weightKg': isCardio ? null : _weight,
                  'restSeconds': isCardio ? null : _rest,
                  'durationMinutes': _duration,
                  'distanceKm': (isCardio || _isCustomMode) && _distance > 0 ? _distance : null,
                  'isCustom': _isCustomMode,
                  'notes': _notesController.text.trim(),
                };

                await context.read<WorkoutDiaryCubit>().addExerciseToDiary(
                  date: widget.selectedDate,
                  itemData: itemData,
                );

                if (!mounted) return;

                await context.read<WorkoutDiaryCubit>().fetchDailyWorkout(widget.selectedDate);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Scheduled $exerciseName in workout diary'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Add to Schedule'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberSpinner({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
    int min = 0,
    int step = 1,
    String suffix = '',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.semiboldStyle.copyWith(fontSize: 14, color: AppTheme.textSecondary)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  if (value > min) {
                    onChanged(value - step);
                  }
                },
                icon: const Icon(Icons.remove, size: 18),
              ),
              Text(
                '$value$suffix',
                style: AppTheme.semiboldStyle.copyWith(fontSize: 16),
              ),
              IconButton(
                onPressed: () {
                  onChanged(value + step);
                },
                icon: const Icon(Icons.add, size: 18),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDoubleSpinner({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
    double min = 0.0,
    double step = 1.0,
    String suffix = '',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.semiboldStyle.copyWith(fontSize: 14, color: AppTheme.textSecondary)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  if (value > min) {
                    onChanged(value - step);
                  }
                },
                icon: const Icon(Icons.remove, size: 18),
              ),
              Text(
                '${value.toStringAsFixed(value % 1 == 0 ? 0 : 1)}$suffix',
                style: AppTheme.semiboldStyle.copyWith(fontSize: 16),
              ),
              IconButton(
                onPressed: () {
                  onChanged(value + step);
                },
                icon: const Icon(Icons.add, size: 18),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
