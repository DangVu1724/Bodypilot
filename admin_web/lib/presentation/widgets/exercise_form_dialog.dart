import 'package:flutter/material.dart';
import 'package:core_shared/core_shared.dart';
import '../../core/theme.dart';

import '../../data/repositories/admin_repository.dart';

class ExerciseFormDialog extends StatefulWidget {
  final ExerciseModel? exercise;

  const ExerciseFormDialog({super.key, this.exercise});

  @override
  State<ExerciseFormDialog> createState() => _ExerciseFormDialogState();
}

class _ExerciseFormDialogState extends State<ExerciseFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _codeController;
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _mediaController;
  late TextEditingController _thumbController;
  late TextEditingController _metController;
  late TextEditingController _durationController;
  String _difficulty = 'BEGINNER';
  String _durationUnit = 'SECONDS';

  bool _isLoading = true;
  List<WorkoutCategoryModel> _categories = [];
  List<BodyPartModel> _bodyParts = [];
  List<MuscleModel> _muscles = [];

  WorkoutCategoryModel? _selectedCategory;
  BodyPartModel? _selectedBodyPart;
  MuscleModel? _selectedTargetMuscle;
  List<MuscleModel> _selectedSecondaryMuscles = [];
  List<String> _selectedEquipment = [];

  final List<String> _commonEquipments = [
    'Trọng lượng cơ thể',
    'Tạ tay',
    'Thanh tạ',
    'Tạ ấm',
    'Cáp',
    'Máy tập',
    'Dây kháng lực',
    'Bóng y học',
    'Ghế tập',
    'Xà đơn',
    'Máy Smith',
    'Không có dụng cụ',
  ];

  @override
  void initState() {
    super.initState();
    final ex = widget.exercise;
    _codeController = TextEditingController(text: ex?.code ?? '');
    _nameController = TextEditingController(text: ex?.name ?? '');
    _descController = TextEditingController(text: ex?.description ?? '');
    _mediaController = TextEditingController(text: ex?.mediaUrl ?? '');
    _thumbController = TextEditingController(text: ex?.thumbnailUrl ?? '');
    _metController = TextEditingController(text: ex?.metValue?.toString() ?? '');
    _durationController = TextEditingController(text: ex?.defaultDuration?.toString() ?? '');

    if (ex?.difficulty != null) {
      _difficulty = ex!.difficulty!;
    }
    if (ex?.durationUnit != null) {
      _durationUnit = ex!.durationUnit!;
    }

    if (ex?.equipment != null) {
      _selectedEquipment = List.from(ex!.equipment!);
    }

    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final futures = await Future.wait([
        adminRepository.getAllWorkoutCategories(),
        adminRepository.getAllBodyParts(),
        adminRepository.getAllMuscles(),
      ]);

      if (!mounted) return;

      setState(() {
        _categories = futures[0] as List<WorkoutCategoryModel>;
        _bodyParts = futures[1] as List<BodyPartModel>;
        _muscles = futures[2] as List<MuscleModel>;

        final ex = widget.exercise;
        if (ex?.category != null) {
          try {
            _selectedCategory = _categories.firstWhere((c) => c.id == ex!.category!.id);
          } catch (_) {}
        }
        if (ex?.bodyPart != null) {
          try {
            _selectedBodyPart = _bodyParts.firstWhere((b) => b.id == ex!.bodyPart!.id);
          } catch (_) {}
        }
        if (ex?.targetMuscle != null) {
          try {
            _selectedTargetMuscle = _muscles.firstWhere((m) => m.id == ex!.targetMuscle!.id);
          } catch (_) {}
        }
        if (ex?.secondaryMuscles != null) {
          _selectedSecondaryMuscles = ex!.secondaryMuscles!.map((em) {
            try {
              return _muscles.firstWhere((m) => m.id == em.id);
            } catch (_) {
              return em;
            }
          }).toList();
        }

        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tải dữ liệu: $e')));
      }
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _descController.dispose();
    _mediaController.dispose();
    _thumbController.dispose();
    _metController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final updatedExercise = ExerciseModel(
        id:
            widget.exercise?.id ??
            '', // BE will generate if empty string is ignored, or we use a separate logic in AdminRepository
        code: _codeController.text,
        name: _nameController.text,
        description: _descController.text,
        mediaUrl: _mediaController.text,
        thumbnailUrl: _thumbController.text,
        difficulty: _difficulty,
        metValue: double.tryParse(_metController.text),
        defaultDuration: int.tryParse(_durationController.text),
        durationUnit: _durationUnit,
        category: _selectedCategory,
        bodyPart: _selectedBodyPart,
        targetMuscle: _selectedTargetMuscle,
        secondaryMuscles: _selectedSecondaryMuscles,
        equipment: _selectedEquipment,
      );
      Navigator.of(context).pop(updatedExercise);
    }
  }

  void _toggleSecondaryMuscle(MuscleModel muscle) {
    setState(() {
      if (_selectedSecondaryMuscles.any((m) => m.id == muscle.id)) {
        _selectedSecondaryMuscles.removeWhere((m) => m.id == muscle.id);
      } else {
        _selectedSecondaryMuscles.add(muscle);
      }
    });
  }

  void _toggleEquipment(String eq) {
    setState(() {
      if (_selectedEquipment.contains(eq)) {
        _selectedEquipment.remove(eq);
      } else {
        _selectedEquipment.add(eq);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.exercise == null ? 'Thêm Bài Tập' : 'Sửa Bài Tập',
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 600,
        child: _isLoading
            ? const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()))
            : SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _codeController,
                        decoration: const InputDecoration(labelText: 'Mã bài tập (Code)'),
                        validator: (v) => v!.isEmpty ? 'Vui lòng nhập mã' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Tên bài tập'),
                        validator: (v) => v!.isEmpty ? 'Vui lòng nhập tên' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descController,
                        decoration: const InputDecoration(labelText: 'Mô tả'),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _difficulty,
                        decoration: const InputDecoration(labelText: 'Độ khó'),
                        items: [
                          'BEGINNER',
                          'INTERMEDIATE',
                          'ADVANCED',
                        ].map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                        onChanged: (v) => setState(() => _difficulty = v!),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _metController,
                              decoration: const InputDecoration(labelText: 'MET Value'),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _durationController,
                              decoration: const InputDecoration(labelText: 'Thời gian mặc định'),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _durationUnit,
                              decoration: const InputDecoration(labelText: 'Đơn vị'),
                              items: [
                                'SECONDS',
                                'MINUTES',
                                'REPS',
                              ].map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                              onChanged: (v) => setState(() => _durationUnit = v!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<WorkoutCategoryModel>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(labelText: 'Nhóm bài tập (Category)'),
                        items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                        onChanged: (v) => setState(() => _selectedCategory = v),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<BodyPartModel>(
                        value: _selectedBodyPart,
                        decoration: const InputDecoration(labelText: 'Bộ phận cơ thể (Body Part)'),
                        items: _bodyParts.map((b) => DropdownMenuItem(value: b, child: Text(b.name))).toList(),
                        onChanged: (v) => setState(() => _selectedBodyPart = v),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<MuscleModel>(
                        value: _selectedTargetMuscle,
                        decoration: const InputDecoration(labelText: 'Nhóm cơ chính (Target Muscle)'),
                        items: _muscles.map((m) => DropdownMenuItem(value: m, child: Text(m.name))).toList(),
                        onChanged: (v) => setState(() => _selectedTargetMuscle = v),
                      ),
                      const SizedBox(height: 12),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Nhóm cơ phụ (Secondary Muscles)',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _muscles.map((m) {
                          final isSelected = _selectedSecondaryMuscles.any((sm) => sm.id == m.id);
                          return FilterChip(
                            label: Text(m.name),
                            selected: isSelected,
                            onSelected: (bool selected) => _toggleSecondaryMuscle(m),
                            selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                            checkmarkColor: AppTheme.primaryColor,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Dụng cụ (Equipment)',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _commonEquipments.map((eq) {
                          final isSelected = _selectedEquipment.contains(eq);
                          return FilterChip(
                            label: Text(eq),
                            selected: isSelected,
                            onSelected: (bool selected) => _toggleEquipment(eq),
                            selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                            checkmarkColor: AppTheme.primaryColor,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _mediaController,
                        decoration: const InputDecoration(labelText: 'Media URL (Video/GIF)'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _thumbController,
                        decoration: const InputDecoration(labelText: 'Thumbnail URL'),
                      ),
                    ],
                  ),
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
          child: const Text('Lưu'),
        ),
      ],
    );
  }
}
