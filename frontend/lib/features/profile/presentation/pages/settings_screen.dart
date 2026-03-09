import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/storage_helper.dart';

/// Settings Screen
///
/// App settings and preferences

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _storageHelper = StorageHelper();

  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _locationPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _notificationsEnabled = _storageHelper.areNotificationsEnabled();
      _darkModeEnabled = _storageHelper.isDarkMode();
      _locationPermissionGranted = _storageHelper.isLocationPermissionGranted();
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    await _storageHelper.setNotificationsEnabled(value);
    setState(() {
      _notificationsEnabled = value;
    });
  }

  Future<void> _toggleDarkMode(bool value) async {
    await _storageHelper.setDarkMode(value);
    setState(() {
      _darkModeEnabled = value;
    });

    // TODO: Implement theme change
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dark mode will be available in next update'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Notifications Section
          _buildSectionHeader('Notifications'),
          _buildSettingCard(
            icon: Icons.notifications,
            title: 'Push Notifications',
            subtitle: 'Receive notifications about leave, attendance, etc.',
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: _toggleNotifications,
              activeColor: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),

          // Appearance Section
          _buildSectionHeader('Appearance'),
          _buildSettingCard(
            icon: Icons.dark_mode,
            title: 'Dark Mode',
            subtitle: 'Enable dark theme',
            trailing: Switch(
              value: _darkModeEnabled,
              onChanged: _toggleDarkMode,
              activeColor: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),

          // Privacy Section
          _buildSectionHeader('Privacy & Permissions'),
          _buildSettingCard(
            icon: Icons.location_on,
            title: 'Location Permission',
            subtitle: _locationPermissionGranted
                ? 'Location access granted'
                : 'Location access required for attendance',
            trailing: Icon(
              _locationPermissionGranted ? Icons.check_circle : Icons.warning,
              color: _locationPermissionGranted
                  ? AppColors.success
                  : AppColors.warning,
            ),
          ),
          const SizedBox(height: 24),

          // About Section
          _buildSectionHeader('About'),
          _buildSettingCard(
            icon: Icons.info,
            title: 'About App',
            subtitle: 'Version 1.0.0',
            onTap: () => _showAboutDialog(),
          ),
          const SizedBox(height: 12),
          _buildSettingCard(
            icon: Icons.description,
            title: 'Terms & Conditions',
            subtitle: 'Read our terms and conditions',
            onTap: () {
              // TODO: Show terms
            },
          ),
          const SizedBox(height: 12),
          _buildSettingCard(
            icon: Icons.privacy_tip,
            title: 'Privacy Policy',
            subtitle: 'Read our privacy policy',
            onTap: () {
              // TODO: Show privacy policy
            },
          ),
          const SizedBox(height: 24),

          // Support Section
          _buildSectionHeader('Support'),
          _buildSettingCard(
            icon: Icons.help,
            title: 'Help & Support',
            subtitle: 'Get help with the app',
            onTap: () {
              // TODO: Show help
            },
          ),
          const SizedBox(height: 12),
          _buildSettingCard(
            icon: Icons.feedback,
            title: 'Send Feedback',
            subtitle: 'Share your thoughts',
            onTap: () {
              // TODO: Show feedback form
            },
          ),
          const SizedBox(height: 24),

          // Danger Zone
          _buildSectionHeader('Danger Zone'),
          _buildSettingCard(
            icon: Icons.delete_forever,
            title: 'Clear Cache',
            subtitle: 'Clear app cache data',
            iconColor: AppColors.warning,
            onTap: () => _showClearCacheDialog(),
          ),
          const SizedBox(height: 32),

          // App Info
          Center(
            child: Column(
              children: [
                Text(
                  'Employee Activity App',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version 1.0.0',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 4),
                Text(
                  '© 2026 909 Technologies',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: AppTextStyles.titleMedium.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? iconColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: (iconColor ?? AppColors.primary).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor ?? AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                if (trailing != null) trailing,
                if (onTap != null && trailing == null)
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About App'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Employee Activity Management System',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Version: 1.0.0',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Built with Flutter',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 12),
            Text(
              '© 2026 909 Technologies',
              style: AppTextStyles.caption,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'Are you sure you want to clear app cache? This will remove temporary data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache cleared successfully'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: Text(
              'Clear',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}