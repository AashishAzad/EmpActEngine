import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/permission_utils.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../data/datasources/attendance_remote_data_source.dart';

/// Mark Attendance Screen
///
/// Captures GPS location and marks attendance.
/// Calls POST /attendance/mark
/// MarkAttendanceRequest: latitude, longitude, address (@NotBlank)

class MarkAttendanceScreen extends StatefulWidget {
  const MarkAttendanceScreen({super.key});

  @override
  State<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> {
  final _dataSource = AttendanceRemoteDataSource(dioClient: DioClient());

  bool _isLoading = false;
  bool _isGettingLocation = false;
  Position? _currentPosition;
  String? _currentAddress;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
      _errorMessage = null;
    });

    try {
      final hasPermission =
      await PermissionUtils.checkAttendancePermissions();

      if (!hasPermission) {
        setState(() {
          _errorMessage =
          'Location permission denied. Please grant permission in settings.';
          _isGettingLocation = false;
        });
        return;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage =
          'Location services are disabled. Please enable GPS.';
          _isGettingLocation = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      // Build address string — address is @NotBlank so always provide a value
      String address = 'Unknown location';
      if (placemarks.isNotEmpty) {
        final place = placemarks[0];
        final parts = [
          place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea,
          place.postalCode,
        ].where((p) => p != null && p.isNotEmpty).toList();
        address = parts.join(', ');
        if (address.isEmpty) address = 'Unknown location';
      }

      setState(() {
        _currentPosition = position;
        _currentAddress = address;
        _isGettingLocation = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to get location: ${e.toString()}';
        _isGettingLocation = false;
      });
    }
  }

  Future<void> _markAttendance() async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait for location to be fetched'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // POST /attendance/mark
      // MarkAttendanceRequest: latitude, longitude, address (@NotBlank)
      await _dataSource.markAttendance(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        address: _currentAddress ?? 'Unknown location',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance marked successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark attendance: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mark Attendance'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: _isGettingLocation
          ? const LoadingIndicator(message: 'Getting your location...')
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Location Icon ────────────────────────────────────────
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: _currentPosition != null
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _currentPosition != null
                      ? Icons.location_on
                      : Icons.location_off,
                  size: 60,
                  color: _currentPosition != null
                      ? AppColors.success
                      : AppColors.error,
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text(
              _currentPosition != null
                  ? 'Location Captured'
                  : 'Location Not Available',
              style: AppTextStyles.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _currentPosition != null
                  ? 'Your location has been successfully captured'
                  : _errorMessage ?? 'Unable to get your location',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // ── Location Details ─────────────────────────────────────
            if (_currentPosition != null) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Location Details',
                        style: AppTextStyles.titleMedium),
                    const SizedBox(height: 16),
                    _buildLocationRow(
                      'Latitude',
                      _currentPosition!.latitude.toStringAsFixed(6),
                      Icons.my_location,
                    ),
                    const SizedBox(height: 12),
                    _buildLocationRow(
                      'Longitude',
                      _currentPosition!.longitude.toStringAsFixed(6),
                      Icons.place,
                    ),
                    const SizedBox(height: 12),
                    _buildLocationRow(
                      'Accuracy',
                      '${_currentPosition!.accuracy.toStringAsFixed(2)}m',
                      Icons.gps_fixed,
                    ),
                    const SizedBox(height: 12),
                    _buildLocationRow(
                      'Address',
                      _currentAddress ?? 'Fetching address...',
                      Icons.location_city,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              CustomButton(
                text: 'Mark Attendance',
                onPressed: _isLoading ? null : _markAttendance,
                isLoading: _isLoading,
                isFullWidth: true,
                icon: Icons.check_circle,
              ),
            ],

            // ── Error / Retry ─────────────────────────────────────────
            if (_currentPosition == null) ...[
              CustomButton(
                text: 'Retry',
                onPressed: _getCurrentLocation,
                isFullWidth: true,
                icon: Icons.refresh,
              ),
              const SizedBox(height: 12),
              CustomButton(
                text: 'Open Settings',
                onPressed: () async =>
                    PermissionUtils.openSettings(),
                variant: ButtonVariant.secondary,
                isFullWidth: true,
                icon: Icons.settings,
              ),
            ],

            const SizedBox(height: 24),

            // Info note
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.info.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: AppColors.info, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your location is used only to verify your attendance '
                          'and is not stored permanently.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.info,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.caption),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTextStyles.bodyMedium
                    .copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}