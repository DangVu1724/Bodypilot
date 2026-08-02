import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mobile/data/models/notification_model.dart';
import 'package:mobile/presentation/bloc/notification/notification_cubit.dart';
import 'package:mobile/presentation/bloc/notification/notification_state.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFA0AEC0), // Slate Grey (Matching Home)
              Color(0xFFD6CCC2), // Warm Beige (Matching Home)
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom Clean Header
              _buildHeader(context),

              // Filter Chips Row
              _buildFilterChips(context),

              // Main Notification List
              Expanded(
                child: BlocBuilder<NotificationCubit, NotificationState>(
                  builder: (context, state) {
                    final items = state.filteredNotifications;

                    if (items.isEmpty) {
                      return _buildEmptyState(state.activeFilter);
                    }

                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _buildNotificationCard(context, item);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E293B), size: 18),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                'Thông Báo',
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF1E293B),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          BlocBuilder<NotificationCubit, NotificationState>(
            builder: (context, state) {
              if (state.unreadCount == 0) return const SizedBox.shrink();
              return TextButton(
                onPressed: () {
                  context.read<NotificationCubit>().markAllAsRead();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã đánh dấu đọc tất cả thông báo'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: const Text(
                  'Đọc tất cả',
                  style: TextStyle(
                    color: Color(0xFFF97316), // Primary Orange
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    return BlocBuilder<NotificationCubit, NotificationState>(
      builder: (context, state) {
        final filters = [
          {'filter': NotificationFilter.all, 'label': 'Tất cả'},
          {'filter': NotificationFilter.unread, 'label': 'Chưa đọc (${state.unreadCount})'},
          {'filter': NotificationFilter.workout, 'label': 'Luyện tập'},
          {'filter': NotificationFilter.meal, 'label': 'Dinh dưỡng'},
          {'filter': NotificationFilter.checkin, 'label': 'Check-in'},
          {'filter': NotificationFilter.system, 'label': 'Hệ thống'},
        ];

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: filters.map((f) {
              final filter = f['filter'] as NotificationFilter;
              final label = f['label'] as String;
              final isSelected = state.activeFilter == filter;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF334155),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: const Color(0xFF1E293B),
                  backgroundColor: Colors.white.withValues(alpha: 0.65),
                  side: BorderSide(
                    color: isSelected ? const Color(0xFF1E293B) : Colors.white.withValues(alpha: 0.4),
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      context.read<NotificationCubit>().setFilter(filter);
                    }
                  },
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildNotificationCard(BuildContext context, NotificationItemModel item) {
    final categoryColor = _getCategoryColor(item.category);
    final categoryIcon = _getCategoryIcon(item.category);

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        context.read<NotificationCubit>().deleteNotification(item.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Đã xóa thông báo'),
            action: SnackBarAction(
              label: 'Hoàn tác',
              onPressed: () {},
            ),
          ),
        );
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 26),
      ),
      child: GestureDetector(
        onTap: () {
          context.read<NotificationCubit>().markAsRead(item.id);
          if (item.routeToPush != null && item.routeToPush!.isNotEmpty) {
            context.push(item.routeToPush!);
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: item.isRead
                ? Colors.white.withValues(alpha: 0.8)
                : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: item.isRead
                  ? Colors.white.withValues(alpha: 0.5)
                  : categoryColor.withValues(alpha: 0.6),
              width: item.isRead ? 1 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: item.isRead ? 0.03 : 0.07),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Icon Avatar
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(categoryIcon, color: categoryColor, size: 22),
              ),
              const SizedBox(width: 14),

              // Content Body
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              color: const Color(0xFF0F172A),
                              fontSize: 15,
                              fontWeight: item.isRead ? FontWeight.w600 : FontWeight.bold,
                            ),
                          ),
                        ),
                        if (!item.isRead)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: categoryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.body,
                      style: TextStyle(
                        color: const Color(0xFF334155).withValues(alpha: item.isRead ? 0.7 : 0.95),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatTimestamp(item.timestamp),
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 11,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: categoryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            item.category.displayName,
                            style: TextStyle(
                              color: categoryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
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
        ),
      ),
    );
  }

  Widget _buildEmptyState(NotificationFilter filter) {
    String title = 'Không có thông báo';
    String sub = 'Bạn hiện không có thông báo nào trong mục này.';

    if (filter == NotificationFilter.unread) {
      title = 'Tất cả đã được đọc! 🎉';
      sub = 'Bạn không có thông báo chưa đọc nào.';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_off_outlined,
              color: Color(0xFF64748B),
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              sub,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.workout:
        return const Color(0xFFF97316); // Orange Primary
      case NotificationCategory.meal:
        return const Color(0xFF10B981); // Emerald Green
      case NotificationCategory.checkin:
        return const Color(0xFF8B5CF6); // Purple
      case NotificationCategory.system:
        return const Color(0xFF2563EB); // Blue
    }
  }

  IconData _getCategoryIcon(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.workout:
        return Icons.fitness_center_rounded;
      case NotificationCategory.meal:
        return Icons.restaurant_rounded;
      case NotificationCategory.checkin:
        return Icons.analytics_rounded;
      case NotificationCategory.system:
        return Icons.notifications_active_rounded;
    }
  }

  String _formatTimestamp(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'Vừa xong';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} phút trước';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} giờ trước';
    } else if (diff.inDays == 1) {
      return 'Hôm qua, ${DateFormat('HH:mm').format(time)}';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ngày trước';
    } else {
      return DateFormat('dd/MM/yyyy HH:mm').format(time);
    }
  }
}
