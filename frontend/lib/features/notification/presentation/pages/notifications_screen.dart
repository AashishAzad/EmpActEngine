import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_utils.dart' as app_date;
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../abstracts/notification_data_source.dart';
import '../../data/datasources/notification_remote_data_source.dart';

/// Notifications Screen
///
/// Shows current user's notification feed.
/// Data from GET /notifications → List<NotificationResponse>
///
/// NotificationResponse fields:
/// id, title, message, type, isGlobal, visibleTill,
/// referenceId, referenceType, createdBy, createdAt,
/// isRead, readAt

class NotificationsScreen extends StatefulWidget {
  NotificationsScreen({
    super.key,
    NotificationDataSource? dataSource,
  }) : dataSource = dataSource ??
            NotificationRemoteDataSource(dioClient: DioClient());

  final NotificationDataSource dataSource;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Use direct datasource — consistent with other feature screens

  bool _isLoading = false;
  List<Map<String, dynamic>> _notifications = [];
  String _selectedFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);

    try {
      // GET /notifications — returns List<NotificationResponse> directly
      final raw = await widget.dataSource.getNotifications();
      setState(() {
        _notifications = raw.cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load notifications: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // ── Filtering ──────────────────────────────────────────────────────────────

  List<Map<String, dynamic>> get _filteredNotifications {
    if (_selectedFilter == 'UNREAD') {
      return _notifications.where((n) => n['isRead'] == false).toList();
    }
    if (_selectedFilter == 'READ') {
      return _notifications.where((n) => n['isRead'] == true).toList();
    }
    return _notifications; // ALL
  }

  int get _unreadCount =>
      _notifications.where((n) => n['isRead'] == false).length;

  // ── Mark As Read ───────────────────────────────────────────────────────────

  Future<void> _markAsRead(String id, bool isRead) async {
    if (isRead) return; // Already read — no-op

    try {
      // PATCH /notifications/{id}/read
      await widget.dataSource.markAsRead(id);

      // Optimistically update local state
      setState(() {
        final index = _notifications.indexWhere((n) => n['id'] == id);
        if (index != -1) {
          _notifications[index] = Map<String, dynamic>.from(_notifications[index])
            ..['isRead'] = true
            ..['readAt'] = DateTime.now().toIso8601String();
        }
      });
    } catch (_) {
      // Non-critical — don't show error for read status
    }
  }

  // ── NOTE: markAllAsRead removed ────────────────────────────────────────────
  // Backend has NO bulk mark-all-read endpoint.
  // Only PATCH /notifications/{id}/read exists per notification.
  // If you need bulk read, it must be added to the backend first.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Notifications'),
            if (_unreadCount > 0)
              Text(
                '$_unreadCount unread',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.white.withOpacity(0.9),
                ),
              ),
          ],
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: Column(
        children: [
          // ── Filter Tabs ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surface,
            child: Row(
              children: [
                _buildFilterTab('ALL', 'All'),
                const SizedBox(width: 12),
                _buildFilterTab('UNREAD', 'Unread'),
                const SizedBox(width: 12),
                _buildFilterTab('READ', 'Read'),
              ],
            ),
          ),

          // ── Notifications List ───────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const LoadingIndicator(message: 'Loading notifications...')
                : _filteredNotifications.isEmpty
                ? EmptyState(
              icon: Icons.notifications_off,
              title: 'No Notifications',
              message: _selectedFilter == 'UNREAD'
                  ? 'You have no unread notifications'
                  : 'No notifications found',
            )
                : RefreshIndicator(
              onRefresh: _loadNotifications,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _filteredNotifications.length,
                itemBuilder: (context, index) {
                  return _buildNotificationCard(
                      _filteredNotifications[index]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String value, String label) {
    final isSelected = _selectedFilter == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilter = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isSelected ? AppColors.white : AppColors.textSecondary,
              fontWeight:
              isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final id = notification['id']?.toString() ?? '';
    final title = notification['title']?.toString() ?? '';
    final message = notification['message']?.toString() ?? '';
    final type = notification['type']?.toString() ?? '';
    final isRead = notification['isRead'] as bool? ?? false;

    // Backend sends LocalDateTime as ISO string e.g. "2026-02-23T20:51:41"
    DateTime createdAt;
    try {
      createdAt = DateTime.parse(
          notification['createdAt']?.toString() ?? '');
    } catch (_) {
      createdAt = DateTime.now();
    }

    final typeColor = _getTypeColor(type);
    final typeIcon = _getTypeIcon(type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isRead
            ? AppColors.surface
            : AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRead
              ? AppColors.border
              : AppColors.primary.withOpacity(0.3),
          width: isRead ? 1 : 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _markAsRead(id, isRead),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(typeIcon, color: typeColor, size: 24),
                ),
                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: AppTextStyles.titleMedium.copyWith(
                                fontWeight: isRead
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                              ),
                            ),
                          ),
                          // Unread dot
                          if (!isRead)
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.access_time,
                              size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            app_date.DateUtils.getTimeAgo(createdAt),
                            style: AppTextStyles.caption,
                          ),
                          // Show type badge
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: typeColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _getTypeLabel(type),
                              style: AppTextStyles.caption.copyWith(
                                color: typeColor,
                                fontWeight: FontWeight.w600,
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
      ),
    );
  }

  // ── Type helpers ─────────────────────────────────────────────────────────
  // Types match AppConstants notification type values:
  // ANNOUNCEMENT, LEAVE_REQUEST, LEAVE_APPROVED, LEAVE_REJECTED,
  // ATTENDANCE_REMINDER, PAYSLIP_GENERATED, LETTER_READY

  Color _getTypeColor(String type) {
    switch (type) {
      case AppConstants.notificationLeaveRequest:
      case AppConstants.notificationLeaveApproved:
      case AppConstants.notificationLeaveRejected:
        return AppColors.warning;
      case AppConstants.notificationPayslipGenerated:
        return AppColors.success;
      case AppConstants.notificationAttendanceReminder:
        return AppColors.primary;
      case AppConstants.notificationLetterReady:
        return AppColors.secondary;
      case AppConstants.notificationAnnouncement:
        return AppColors.info;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case AppConstants.notificationLeaveRequest:
      case AppConstants.notificationLeaveApproved:
      case AppConstants.notificationLeaveRejected:
        return Icons.event_busy;
      case AppConstants.notificationPayslipGenerated:
        return Icons.account_balance_wallet;
      case AppConstants.notificationAttendanceReminder:
        return Icons.location_on;
      case AppConstants.notificationLetterReady:
        return Icons.description;
      case AppConstants.notificationAnnouncement:
        return Icons.campaign;
      default:
        return Icons.notifications;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case AppConstants.notificationLeaveRequest:
        return 'Leave';
      case AppConstants.notificationLeaveApproved:
        return 'Approved';
      case AppConstants.notificationLeaveRejected:
        return 'Rejected';
      case AppConstants.notificationPayslipGenerated:
        return 'Payslip';
      case AppConstants.notificationAttendanceReminder:
        return 'Attendance';
      case AppConstants.notificationLetterReady:
        return 'Letter';
      case AppConstants.notificationAnnouncement:
        return 'Announcement';
      default:
        return type;
    }
  }
}