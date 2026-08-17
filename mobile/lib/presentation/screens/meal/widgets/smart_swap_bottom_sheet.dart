import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/utils/category_image_helper.dart';
import 'package:mobile/data/models/food_smart_swap_model.dart';
import 'package:mobile/presentation/bloc/smart_swap/smart_swap_cubit.dart';
import 'package:mobile/presentation/bloc/smart_swap/smart_swap_state.dart';

class SmartSwapBottomSheet extends StatefulWidget {
  final String foodId;
  final String currentFoodName;
  final double currentServingQuantity;
  final Function(FoodSmartSwapCandidateModel candidate)? onFoodSwapped;

  const SmartSwapBottomSheet({
    super.key,
    required this.foodId,
    required this.currentFoodName,
    this.currentServingQuantity = 100.0,
    this.onFoodSwapped,
  });

  static void show(
    BuildContext context, {
    required String foodId,
    required String currentFoodName,
    double currentServingQuantity = 100.0,
    Function(FoodSmartSwapCandidateModel candidate)? onFoodSwapped,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => BlocProvider(
        create: (context) => SmartSwapCubit()..fetchFoodCandidates(foodId, currentServingQuantity: currentServingQuantity),
        child: SmartSwapBottomSheet(
          foodId: foodId,
          currentFoodName: currentFoodName,
          currentServingQuantity: currentServingQuantity,
          onFoodSwapped: onFoodSwapped,
        ),
      ),
    );
  }

  @override
  State<SmartSwapBottomSheet> createState() => _SmartSwapBottomSheetState();
}

class _SmartSwapBottomSheetState extends State<SmartSwapBottomSheet> {
  String _selectedTagFilter = 'ALL';
  double _customGramSlider = 100.0;

  @override
  void initState() {
    super.initState();
    _customGramSlider = widget.currentServingQuantity > 0 ? widget.currentServingQuantity : 100.0;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
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

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF7A30).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.swap_horizontal_circle_rounded, color: Color(0xFFFF7A30), size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Smart Swap Gợi Ý Đổi Món',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        'Đổi "${widget.currentFoodName}" sang món khuyên dùng tương đương',
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Filter Chips Row
          _buildFilterChips(),

          const Divider(height: 20),

          // Candidates List
          Expanded(
            child: BlocBuilder<SmartSwapCubit, SmartSwapState>(
              builder: (context, state) {
                if (state is SmartSwapLoading) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Color(0xFFFF7A30)),
                        SizedBox(height: 16),
                        Text('Đang tìm các món ăn khuyên dùng phù hợp...'),
                      ],
                    ),
                  );
                }

                if (state is SmartSwapError) {
                  return Center(
                    child: Text('Lỗi: ${state.message}', style: const TextStyle(color: Colors.red)),
                  );
                }

                if (state is FoodSmartSwapLoaded) {
                  final allCandidates = state.candidates;
                  final filtered = _applyTagFilter(allCandidates);

                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text('Không tìm thấy món ăn phù hợp với tiêu chí lọc.'),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    physics: const BouncingScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final candidate = filtered[index];
                      return _buildCandidateCard(context, candidate);
                    },
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'key': 'ALL', 'label': 'Tất cả'},
      {'key': 'HIGH_PROTEIN', 'label': '🥩 Tăng Protein'},
      {'key': 'LOW_CALORIE', 'label': '🥗 Giảm Calo'},
      {'key': 'BALANCED', 'label': '⚖️ Cân bằng'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedTagFilter == f['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                f['label']!,
                style: GoogleFonts.plusJakartaSans(
                  color: isSelected ? Colors.white : const Color(0xFF334155),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              selected: isSelected,
              selectedColor: const Color(0xFFFF7A30),
              backgroundColor: const Color(0xFFF1F5F9),
              side: BorderSide.none,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedTagFilter = f['key']!;
                  });
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  List<FoodSmartSwapCandidateModel> _applyTagFilter(List<FoodSmartSwapCandidateModel> list) {
    if (_selectedTagFilter == 'ALL') return list;
    return list.where((c) => c.swapGroup == _selectedTagFilter).toList();
  }

  Widget _buildCandidateCard(BuildContext context, FoodSmartSwapCandidateModel candidate) {
    final imagePath = getCategoryAssetPath(null, candidate.categoryName);

    // Calculate realtime scaling based on slider ratio
    final double baseQty = candidate.recommendedServingQuantity > 0 ? candidate.recommendedServingQuantity : 100.0;
    final double scale = _customGramSlider / baseQty;

    final double scaledCal = candidate.calories * scale;
    final double scaledP = candidate.protein * scale;
    final double scaledC = candidate.carbs * scale;
    final double scaledF = candidate.fat * scale;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  imagePath,
                  width: 58,
                  height: 58,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 58,
                    height: 58,
                    color: Colors.orange[50],
                    child: const Icon(Icons.restaurant_rounded, color: Color(0xFFFF7A30)),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      candidate.foodName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            candidate.matchReason,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Portion Slider
          Row(
            children: [
              Text(
                'Khẩu phần: ${_customGramSlider.toStringAsFixed(0)}g',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFF7A30),
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                    activeTrackColor: const Color(0xFFFF7A30),
                    inactiveTrackColor: Colors.grey[200],
                    thumbColor: const Color(0xFFFF7A30),
                  ),
                  child: Slider(
                    value: _customGramSlider.clamp(50.0, 500.0),
                    min: 50.0,
                    max: 500.0,
                    divisions: 45,
                    onChanged: (val) {
                      setState(() {
                        _customGramSlider = val;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Macros
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMacroChip('🔥 ${scaledCal.toStringAsFixed(0)} kcal'),
              _buildMacroChip('🥩 P: ${scaledP.toStringAsFixed(1)}g'),
              _buildMacroChip('🍚 C: ${scaledC.toStringAsFixed(1)}g'),
              _buildMacroChip('🥑 F: ${scaledF.toStringAsFixed(1)}g'),
            ],
          ),
          const SizedBox(height: 14),

          // Select Button
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF7A30),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.pop(context);
                final updatedCandidate = FoodSmartSwapCandidateModel(
                  foodId: candidate.foodId,
                  foodName: candidate.foodName,
                  categoryName: candidate.categoryName,
                  imageUrl: candidate.imageUrl,
                  recommendedServingQuantity: _customGramSlider,
                  calories: scaledCal,
                  protein: scaledP,
                  fat: scaledF,
                  carbs: scaledC,
                  matchScore: candidate.matchScore,
                  matchReason: candidate.matchReason,
                  swapGroup: candidate.swapGroup,
                );
                widget.onFoodSwapped?.call(updatedCandidate);
              },
              child: Text(
                'Chọn đổi món (${_customGramSlider.toStringAsFixed(0)}g)',
                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
      ),
    );
  }
}
