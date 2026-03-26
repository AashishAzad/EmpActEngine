import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_utils.dart' as app_date;
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../data/datasources/attendance_remote_data_source.dart';

/// Attendance History Screen
///
/// Shows monthly attendance records.
/// Data from GET /attendance/my-attendance?month=&year= → List<AttendanceResponse>
///
/// AttendanceResponse fields:
/// id, date (LocalDate), status (AttendanceStatus),
/// latitude, longitude, address,
/// checkInTime (LocalDateTime), checkOutTime (LocalDateTime),
/// createdAt

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  final _dataSource = AttendanceRemoteDataSource(dioClient: DioClient());

  DateTime _selectedMonth = DateTime.now();
  bool _isLoading = false;
  List<Map<String, dynamic>> _attendanceRecords = [];

  @override
  void initState() {
    super.initState();
    _loadAttendanceHistory();
  }

  Future<void> _loadAttendanceHistory() async {
    setState(() => _isLoading = true);
    try {
      // GET /attendance/my-attendance → List<AttendanceResponse> directly
      final raw = await _dataSource.getAttendanceHistory(
        month: _selectedMonth.month,
        year: _selectedMonth.year,
      );
      setState(() {
        _attendanceRecords = _buildMonthlyAttendanceRecords(
          raw.cast<Map<String, dynamic>>(),
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load history: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + delta,
      );
    });
    _loadAttendanceHistory();
  }

  // ── Summary counts from records ────────────────────────────────────────────

  int get _presentCount =>
      _attendanceRecords.where((r) => r['status'] == 'PRESENT').length;

  int get _absentCount =>
      _attendanceRecords.where((r) => r['status'] == 'ABSENT').length;

  int get _percentage {
    final workingDayCount = _attendanceRecords
        .where((r) => r['status'] != 'WEEKEND')
        .length;
    if (workingDayCount == 0) return 0;
    return (_presentCount / workingDayCount * 100).round();
  }

  List<Map<String, dynamic>> _buildMonthlyAttendanceRecords(
    List<Map<String, dynamic>> rawRecords,
  ) {
    final recordsByDate = <String, Map<String, dynamic>>{};

    for (final record in rawRecords) {
      final rawDate = record['date']?.toString();
      if (rawDate == null || rawDate.isEmpty) continue;
      recordsByDate[rawDate] = Map<String, dynamic>.from(record);
    }

    final now = DateTime.now();
    final isCurrentMonth = _selectedMonth.year == now.year &&
        _selectedMonth.month == now.month;
    final lastVisibleDay = isCurrentMonth
        ? now.day
        : DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;

    final monthlyRecords = <Map<String, dynamic>>[];

    for (int day = lastVisibleDay; day >= 1; day--) {
      final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);
      final isoDate = DateFormat('yyyy-MM-dd').format(date);
      monthlyRecords.add(
        recordsByDate[isoDate] ??
            {
              'date': isoDate,
              'status': date.weekday == DateTime.saturday ||
                      date.weekday == DateTime.sunday
                  ? 'WEEKEND'
                  : 'ABSENT',
              'checkInTime': null,
              'checkOutTime': null,
            },
      );
    }

    return monthlyRecords;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Attendance History'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: Column(
        children: [
          // ── Month Selector ───────────────────────────────────────────────
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _changeMonth(-1),
                ),
                Text(
                  DateFormat('MMMM yyyy').format(_selectedMonth),
                  style: AppTextStyles.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _selectedMonth.month == DateTime.now().month &&
                      _selectedMonth.year == DateTime.now().year
                      ? null
                      : () => _changeMonth(1),
                ),
              ],
            ),
          ),

          // ── Summary Cards ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Present',
                    _presentCount.toString(),
                    AppColors.success,
                    Icons.check_circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Absent',
                    _absentCount.toString(),
                    AppColors.error,
                    Icons.event_busy,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Attendance',
                    '$_percentage%',
                    AppColors.primary,
                    Icons.percent,
                  ),
                ),
              ],
            ),
          ),

          // ── Attendance List ──────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const LoadingIndicator(message: 'Loading attendance...')
                : _attendanceRecords.isEmpty
                    ? const EmptyState(
                        icon: Icons.event_note,
                        title: 'No Attendance Records',
                        message: 'No attendance records found for this month',
                      )
                : RefreshIndicator(
                    onRefresh: _loadAttendanceHistory,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _attendanceRecords.length,
                      itemBuilder: (context, index) =>
                          _buildAttendanceCard(_attendanceRecords[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.titleLarge.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(title, style: AppTextStyles.caption),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(Map<String, dynamic> record) {
    // date is LocalDate → serializes as "2026-02-23"
    DateTime? date;
    try {
      date = DateTime.parse(record['date']);
    } catch (_) {}

    if (date == null) return const SizedBox.shrink();

    final status = record['status']?.toString() ?? 'UNKNOWN';
    final statusColor = switch (status) {
      'ABSENT' => AppColors.error,
      'WEEKEND' => AppColors.textSecondary,
      _ => AppColors.getAttendanceColor(status),
    };
    final isToday = app_date.DateUtils.isToday(date);
    final statusLabel = _formatStatusLabel(status);

    // checkInTime / checkOutTime are LocalDateTime → "2026-02-23T09:15:00"
    // Format to show time only: "09:15 AM"
    final checkInRaw = record['checkInTime']?.toString();
    final checkOutRaw = record['checkOutTime']?.toString();
    final checkIn = _formatTime(checkInRaw);
    final checkOut = _formatTime(checkOutRaw);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isToday ? AppColors.primary : AppColors.border,
          width: isToday ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // ── Date Circle ────────────────────────────────────────────────
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  date.day.toString(),
                  style: AppTextStyles.titleLarge.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  app_date.DateUtils.getShortDayName(date),
                  style: AppTextStyles.caption.copyWith(
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // ── Details ────────────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      app_date.DateUtils.formatDate(date),
                      style: AppTextStyles.titleMedium,
                    ),
                    if (isToday) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Today',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      status == 'PRESENT'
                          ? Icons.check_circle
                          : status == 'WEEKEND'
                              ? Icons.weekend
                          : Icons.event_busy,
                      size: 14,
                      color: statusColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      statusLabel,
                      style: AppTextStyles.caption.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                // Show check-in/out times for PRESENT records
                if (status == 'PRESENT' && checkIn != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'In: $checkIn${checkOut != null ? ' · Out: $checkOut' : ''}',
                    style: AppTextStyles.caption,
                  ),
                ],
              ],
            ),
          ),

          Icon(Icons.arrow_forward_ios,
              size: 16, color: AppColors.textSecondary),
        ],
      ),
    );
  }

  /// Format LocalDateTime ISO string to "09:15 AM"
  /// Input: "2026-02-23T09:15:00" or null
  String? _formatTime(String? isoString) {
    if (isoString == null) return null;
    try {
      final dt = DateTime.parse(isoString);
      return DateFormat('hh:mm a').format(dt);
    } catch (_) {
      return isoString; // fallback: show raw if parse fails
    }
  }

  String _formatStatusLabel(String status) {
    switch (status.trim().toUpperCase()) {
      case 'PRESENT':
      case 'MANUAL_APPROVED':
        return 'Present';
      case 'ABSENT':
        return 'Absent';
      case 'LEAVE':
        return 'Leave';
      case 'HOLIDAY':
        return 'Holiday';
      case 'WEEKEND':
        return 'Weekend';
      default:
        return status;
    }
  }
}
