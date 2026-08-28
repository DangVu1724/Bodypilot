import 'package:core_shared/core_shared.dart';
import 'package:flutter/material.dart';

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
          _selectedSecondaryMuscles = _muscles.where((m) => ex!.secondaryMuscles!.any((sm) => sm.id == m.id)).toList();
        }

        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
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
        id: widget.exercise?.id ?? '',
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

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.exercise != null;

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 780,
        constraints: const BoxConstraints(maxHeight: 850),
        padding: const EdgeInsets.all(32),
        child: _isLoading
            ? const SizedBox(
                height: 250,
                child: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.fitness_center_rounded, color: AppTheme.primaryColor, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEdit ? 'Sửa Bài Tập' : 'Thêm Bài Tập Mới',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isEdit
                                    ? 'Cập nhật thông tin chi tiết bài tập'
                                    : 'Điền đầy đủ thông tin để tạo bài tập mới',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const Divider(height: 32, color: Color(0xFFF1F5F9)),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _codeController,
                                    decoration: _buildInputDecoration('Mã bài tập (Code)'),
                                    validator: (v) => v!.isEmpty ? 'Vui lòng nhập mã' : null,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _nameController,
                                    decoration: _buildInputDecoration('Tên bài tập'),
                                    validator: (v) => v!.isEmpty ? 'Vui lòng nhập tên' : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _descController,
                              decoration: _buildInputDecoration('Mô tả hướng dẫn bài tập'),
                              maxLines: 3,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _difficulty,
                                    decoration: _buildInputDecoration('Độ khó'),
                                    items: [
                                      'BEGINNER',
                                      'INTERMEDIATE',
                                      'ADVANCED',
                                    ].map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                                    onChanged: (v) => setState(() => _difficulty = v!),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _metController,
                                    decoration: _buildInputDecoration('Chỉ số MET Value'),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: _durationController,
                                    decoration: _buildInputDecoration('Thời gian mặc định'),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 1,
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _durationUnit,
                                    decoration: _buildInputDecoration('Đơn vị'),
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
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<WorkoutCategoryModel>(
                                    initialValue: _selectedCategory,
                                    decoration: _buildInputDecoration('Danh mục bài tập'),
                                    items: _categories
                                        .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                                        .toList(),
                                    onChanged: (v) => setState(() => _selectedCategory = v),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: DropdownButtonFormField<BodyPartModel>(
                                    initialValue: _selectedBodyPart,
                                    decoration: _buildInputDecoration('Bộ phận cơ thể'),
                                    items: _bodyParts
                                        .map((b) => DropdownMenuItem(value: b, child: Text(b.name)))
                                        .toList(),
                                    onChanged: (v) => setState(() => _selectedBodyPart = v),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<MuscleModel>(
                              initialValue: _selectedTargetMuscle,
                              decoration: _buildInputDecoration('Nhóm cơ tác động chính (Target Muscle)'),
                              items: _muscles.map((m) => DropdownMenuItem(value: m, child: Text(m.name))).toList(),
                              onChanged: (v) => setState(() => _selectedTargetMuscle = v),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Nhóm cơ phụ tác động (Secondary Muscles)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _muscles.map((m) {
                                final isSelected = _selectedSecondaryMuscles.any((sm) => sm.id == m.id);
                                return FilterChip(
                                  label: Text(m.name),
                                  selected: isSelected,
                                  onSelected: (_) => _toggleSecondaryMuscle(m),
                                  backgroundColor: const Color(0xFFF1F5F9),
                                  selectedColor: AppTheme.primaryLight,
                                  checkmarkColor: AppTheme.primaryColor,
                                  labelStyle: TextStyle(
                                    color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: BorderSide(
                                      color: isSelected ? AppTheme.primaryColor : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Dụng cụ tập luyện (Equipment)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _commonEquipments.map((eq) {
                                final isSelected = _selectedEquipment.contains(eq);
                                return FilterChip(
                                  label: Text(eq),
                                  selected: isSelected,
                                  onSelected: (_) => _toggleEquipment(eq),
                                  backgroundColor: const Color(0xFFF1F5F9),
                                  selectedColor: AppTheme.primaryLight,
                                  checkmarkColor: AppTheme.primaryColor,
                                  labelStyle: TextStyle(
                                    color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: BorderSide(
                                      color: isSelected ? AppTheme.primaryColor : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _mediaController,
                                    decoration: _buildInputDecoration('Đường dẫn Video / GIF bài tập'),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _thumbController,
                                    decoration: _buildInputDecoration('Đường dẫn Hình ảnh Thumbnail'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        child: const Text(
                          'Hủy bỏ',
                          style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text('Lưu bài tập', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
