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

                  return Column(
                    children: [
                      _buildFilterChips(allCandidates),
                      const Divider(height: 20),
                      Expanded(
                        child: filtered.isEmpty
                            ? const Center(
                                child: Text('Không tìm thấy món ăn phù hợp với tiêu chí lọc.'),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                                physics: const BouncingScrollPhysics(),
                                itemCount: filtered.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 14),
                                itemBuilder: (context, index) {
                                  final candidate = filtered[index];
                                  return _buildCandidateCard(context, candidate);
                                },
                              ),
                      ),
                    ],
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

  Widget _buildFilterChips(List<FoodSmartSwapCandidateModel> candidates) {
    final Set<String> categoryCodes = candidates
        .map((c) {
          String g = (c.swapGroup ?? '').toUpperCase();
          return g == 'VEG' ? 'VEGETABLE' : g;
        })
        .where((code) => code.isNotEmpty)
        .toSet();

    final List<Map<String, String>> filters = [
      {'key': 'ALL', 'label': 'Tất cả'},
    ];

    for (final code in categoryCodes) {
      final chipInfo = _getCategoryChipInfo(code);
      if (chipInfo != null && !filters.any((f) => f['key'] == chipInfo['key'])) {
        filters.add(chipInfo);
      }
    }

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

  Map<String, String>? _getCategoryChipInfo(String code) {
    switch (code) {
      case 'MEAT':
        return {'key': 'MEAT', 'label': '🥩 Thịt'};
      case 'SEAFOOD':
        return {'key': 'SEAFOOD', 'label': '🦐 Hải sản'};
      case 'FRUIT':
        return {'key': 'FRUIT', 'label': '🍎 Trái cây'};
      case 'BEVERAGE':
        return {'key': 'BEVERAGE', 'label': '🧃 Đồ uống'};
      case 'DAIRY':
        return {'key': 'DAIRY', 'label': '🥛 Sữa & Hạt'};
      case 'GRAIN':
        return {'key': 'GRAIN', 'label': '🍚 Cơm & Ngũ cốc'};
      case 'DRY_DISH':
        return {'key': 'DRY_DISH', 'label': '🥖 Món khô'};
      case 'NOODLE_SOUP':
        return {'key': 'NOODLE_SOUP', 'label': '🍜 Món nước'};
      case 'VEGETABLE':
      case 'VEG':
        return {'key': 'VEGETABLE', 'label': '🥗 Rau củ'};
      default:
        return {'key': code, 'label': '🍲 $code'};
    }
  }

  List<FoodSmartSwapCandidateModel> _applyTagFilter(List<FoodSmartSwapCandidateModel> list) {
    if (_selectedTagFilter == 'ALL') return list;
    return list.where((c) {
      String group = (c.swapGroup ?? '').toUpperCase();
      if (group == 'VEG') group = 'VEGETABLE';
      return group == _selectedTagFilter;
    }).toList();
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
                        Builder(
                          builder: (context) {
                            final text = candidate.matchReason;
                            Color bgColor = const Color(0xFF10B981).withValues(alpha: 0.12);
                            Color textColor = const Color(0xFF10B981);

                            if (text.contains('Không khuyên dùng')) {
                              bgColor = const Color(0xFFF59E0B).withValues(alpha: 0.12);
                              textColor = const Color(0xFFD97706);
                            } else if (text == 'Ổn') {
                              bgColor = const Color(0xFF3B82F6).withValues(alpha: 0.12);
                              textColor = const Color(0xFF2563EB);
                            }

                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                text,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                            );
                          },
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

          // Macros (Cuộn ngang linh hoạt chống overflow)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildMacroChip('🔥 ${scaledCal.toStringAsFixed(0)} kcal'),
                const SizedBox(width: 6),
                _buildMacroChip('🥩 P: ${scaledP.toStringAsFixed(1)}g'),
                const SizedBox(width: 6),
                _buildMacroChip('🍚 C: ${scaledC.toStringAsFixed(1)}g'),
                const SizedBox(width: 6),
                _buildMacroChip('🥑 F: ${scaledF.toStringAsFixed(1)}g'),
              ],
            ),
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
