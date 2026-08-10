import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/utils/category_image_helper.dart';
import 'package:mobile/data/models/food_smart_swap_model.dart';
import 'package:mobile/presentation/bloc/smart_swap/smart_swap_cubit.dart';
import 'package:mobile/presentation/bloc/smart_swap/smart_swap_state.dart';

class SmartSwapBottomSheet extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
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
                    color: const Color(0xFFFF7A30).withOpacity(0.12),
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
                        'Smart Swap Thông Minh',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        'Đổi "$currentFoodName" sang món tương đương',
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

          const Divider(height: 24),

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
                        Text('AI đang tìm món ăn tương đồng dinh dưỡng...'),
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
                  final candidates = state.candidates;
                  if (candidates.isEmpty) {
                    return const Center(
                      child: Text('Không tìm thấy món ăn phù hợp để thay thế.'),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    physics: const BouncingScrollPhysics(),
                    itemCount: candidates.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final candidate = candidates[index];
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

  Widget _buildCandidateCard(BuildContext context, FoodSmartSwapCandidateModel candidate) {
    final imagePath = getCategoryAssetPath(null, candidate.categoryName);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Food Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  imagePath,
                  width: 54,
                  height: 54,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 54,
                    height: 54,
                    color: Colors.orange[50],
                    child: const Icon(Icons.restaurant_rounded, color: Color(0xFFFF7A30)),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Title & Category
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      candidate.foodName,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Khẩu phần đề xuất: ${candidate.recommendedServingQuantity.toStringAsFixed(0)}g',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFFF7A30),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Macros
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMacroChip('🔥 ${candidate.calories.toStringAsFixed(0)} kcal'),
              _buildMacroChip('🥩 P: ${candidate.protein.toStringAsFixed(1)}g'),
              _buildMacroChip('🍚 C: ${candidate.carbs.toStringAsFixed(1)}g'),
              _buildMacroChip('🥑 F: ${candidate.fat.toStringAsFixed(1)}g'),
            ],
          ),
          const SizedBox(height: 10),

          // Compact Select Button
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              height: 32,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7A30),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  onFoodSwapped?.call(candidate);
                },
                child: Text(
                  'Chọn đổi món',
                  style: GoogleFonts.beVietnamPro(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.12)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
      ),
    );
  }
}
