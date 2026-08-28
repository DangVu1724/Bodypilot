import 'package:flutter/material.dart';
import '../../core/theme.dart';

class CategoryFilterItem {
  final String? id; // null = 'Tất cả'
  final String label;

  const CategoryFilterItem({this.id, required this.label});
}

class BaseTableScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<String> columns;
  final List<DataRow> rows;
  final VoidCallback? onAddPressed;
  final VoidCallback? onRefresh;
  final ValueChanged<String>? onSearchChanged;
  final String? searchHint;
  final int currentPage;
  final int totalPages;
  final int totalElements;
  final int pageSize;
  final ValueChanged<int>? onPageChanged;
  final bool isLoading;

  // Dynamic Category Filters
  final List<CategoryFilterItem>? categoryFilters;
  final String? selectedCategoryId;
  final ValueChanged<String?>? onCategorySelected;

  const BaseTableScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.columns,
    required this.rows,
    this.onAddPressed,
    this.onRefresh,
    this.onSearchChanged,
    this.searchHint,
    this.currentPage = 0,
    this.totalPages = 1,
    this.totalElements = 0,
    this.pageSize = 20,
    this.onPageChanged,
    this.isLoading = false,
    this.categoryFilters,
    this.selectedCategoryId,
    this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final int startItem = totalElements == 0 ? 0 : (currentPage * pageSize) + 1;
    final int endItem = ((currentPage + 1) * pageSize) > totalElements
        ? totalElements
        : ((currentPage + 1) * pageSize);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section (STAYS VISIBLE AT ALL TIMES)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              Row(
                children: [
                  if (onRefresh != null) ...[
                    IconButton(
                      onPressed: onRefresh,
                      icon: const Icon(Icons.refresh_rounded, color: AppTheme.textSecondary, size: 20),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: AppTheme.borderColor),
                        padding: const EdgeInsets.all(12),
                      ),
                      tooltip: 'Làm mới dữ liệu',
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (onAddPressed != null)
                    ElevatedButton.icon(
                      onPressed: onAddPressed,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text('Thêm mới $title'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Control Bar Above Table (Category Filter Pills & Search - STAYS VISIBLE AT ALL TIMES)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Row(
              children: [
                // Scrollable Category Filter Pills
                if (categoryFilters != null && categoryFilters!.isNotEmpty)
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: categoryFilters!.map((cat) {
                          final bool isSelected = cat.id == selectedCategoryId;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: InkWell(
                              onTap: () {
                                if (onCategorySelected != null) {
                                  onCategorySelected!(cat.id);
                                }
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: _buildFilterPill(cat.label, isSelected: isSelected),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildFilterPill('Tất cả', isSelected: true),
                    ],
                  ),
                const SizedBox(width: 16),

                // Search Bar
                if (onSearchChanged != null)
                  Container(
                    width: 260,
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFEBECEF)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded, color: AppTheme.textSecondary, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            onChanged: onSearchChanged,
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: searchHint ?? 'Tìm kiếm...',
                              hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Data Table Container (SKELETON LOADER IF LOADING)
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                left: BorderSide(color: AppTheme.borderColor),
                right: BorderSide(color: AppTheme.borderColor),
              ),
            ),
            child: isLoading
                ? _buildTableSkeleton()
                : LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minWidth: constraints.maxWidth),
                          child: DataTable(
                            headingRowHeight: 50,
                            dataRowMaxHeight: 64,
                            headingRowColor: WidgetStateProperty.all(const Color(0xFFFAFAFA)),
                            columns: columns
                                .map((c) => DataColumn(
                                      label: Text(
                                        c,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ))
                                .toList(),
                            rows: rows,
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Pagination Footer (STAYS VISIBLE AT ALL TIMES)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isLoading
                      ? 'Đang tải dữ liệu...'
                      : 'Hiển thị $startItem - $endItem trong số $totalElements bản ghi',
                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                ),
                if (onPageChanged != null)
                  Row(
                    children: [
                      // Previous Page Button
                      IconButton(
                        onPressed: (!isLoading && currentPage > 0) ? () => onPageChanged!(currentPage - 1) : null,
                        icon: const Icon(Icons.chevron_left_rounded, size: 20),
                        style: IconButton.styleFrom(
                          backgroundColor: (!isLoading && currentPage > 0) ? const Color(0xFFF8F9FA) : Colors.transparent,
                          side: const BorderSide(color: AppTheme.borderColor),
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Page Indicator Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Trang ${currentPage + 1} / ${totalPages == 0 ? 1 : totalPages}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Next Page Button
                      IconButton(
                        onPressed: (!isLoading && currentPage + 1 < totalPages) ? () => onPageChanged!(currentPage + 1) : null,
                        icon: const Icon(Icons.chevron_right_rounded, size: 20),
                        style: IconButton.styleFrom(
                          backgroundColor: (!isLoading && currentPage + 1 < totalPages) ? const Color(0xFFF8F9FA) : Colors.transparent,
                          side: const BorderSide(color: AppTheme.borderColor),
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Skeleton Table Loader Placeholder
  Widget _buildTableSkeleton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: List.generate(6, (index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Row(
              children: [
                _buildSkeletonPill(width: 50, height: 16),
                const SizedBox(width: 32),
                _buildSkeletonPill(width: 160, height: 16),
                const SizedBox(width: 32),
                _buildSkeletonPill(width: 110, height: 16),
                const SizedBox(width: 32),
                _buildSkeletonPill(width: 80, height: 16),
                const SizedBox(width: 32),
                _buildSkeletonPill(width: 70, height: 16),
                const Spacer(),
                _buildSkeletonPill(width: 90, height: 28, radius: 10),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSkeletonPill({required double width, required double height, double radius = 6}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  Widget _buildFilterPill(String label, {required bool isSelected}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryLight : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: isSelected ? Border.all(color: const Color(0xFFFFD5C6)) : Border.all(color: Colors.transparent),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
        ),
      ),
    );
  }
}
