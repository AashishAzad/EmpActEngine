import 'package:employee_activity_app/features/home/presentation/pages/attendance_page.dart';
import 'package:employee_activity_app/features/home/presentation/pages/dashboard_page.dart';
import 'package:employee_activity_app/features/home/presentation/pages/leaves_page.dart';
import 'package:employee_activity_app/features/home/presentation/pages/more_page.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Home Screen
///
/// Main screen with bottom navigation.
/// Contains: Dashboard, Attendance, Leaves, More
///
/// Each page manages its own BlocBuilder internally,
/// so no need to wrap the whole scaffold in one here.

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    DashboardPage(),
    AttendancePage(),
    LeavesPage(),
    MorePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'Attendance',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Leaves',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            label: 'More',
          ),
        ],
      ),
    );
  }
}