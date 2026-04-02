import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'admin_home_screen.dart';
import 'correction_screen.dart';
import 'company_screen.dart';
import 'generator_screen.dart';

/// Admin Home Wrapper
///
/// Bottom navigation for admin with 4 tabs:
/// - Home (Notification Feed)
/// - Correction (Edit Employee Details)
/// - Company (Manage Employees)
/// - Generator (Payslips & Letters)

class AdminHomeWrapper extends StatefulWidget {
  AdminHomeWrapper({
    super.key,
    List<Widget>? pages,
  }) : pages = pages ??
            [
              AdminHomeScreen(),
              CorrectionScreen(),
              CompanyScreen(),
              GeneratorScreen(),
            ];

  final List<Widget> pages;

  @override
  State<AdminHomeWrapper> createState() => _AdminHomeWrapperState();
}

class _AdminHomeWrapperState extends State<AdminHomeWrapper> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // ✅ FIXED: Use only the current page's Scaffold (no wrapper Scaffold)
    // This prevents multiple FABs from being active simultaneously
    return Stack(
      children: [
        // Show current page
        widget.pages[_currentIndex],

        // Bottom navigation bar overlay
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textSecondary,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.edit),
                label: 'Correction',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.business),
                label: 'Company',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long),
                label: 'Generator',
              ),
            ],
          ),
        ),
      ],
    );
  }
}