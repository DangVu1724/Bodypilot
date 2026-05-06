import 'package:flutter/material.dart';
import '../../core/theme.dart';

class BaseTableScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<String> columns;
  final List<DataRow> rows;
  final VoidCallback? onAddPressed;
  final VoidCallback? onRefresh;

  const BaseTableScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.columns,
    required this.rows,
    this.onAddPressed,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
              Row(
                children: [
                  if (onRefresh != null) ...[
                    OutlinedButton.icon(
                      onPressed: onRefresh,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Làm mới'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textSecondary,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (onAddPressed != null)
                    ElevatedButton.icon(
                      onPressed: onAddPressed,
                      icon: const Icon(Icons.add, size: 18),
                      label: Text('Thêm $title'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
              columns: columns
                  .map((c) => DataColumn(
                        label: Text(
                          c,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                      ))
                  .toList(),
              rows: rows,
            ),
          ),
        ],
      ),
    );
  }
}
