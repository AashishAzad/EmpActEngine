import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/admin/presentation/pages/admin_home_wrapper.dart';

/// Role-Based Home Wrapper
///
/// Shows different home screens based on user role:
/// - ADMIN/MANAGER → Admin Home with bottom navigation
/// - EMPLOYEE → Employee Home with bottom navigation

class RoleBasedHomeWrapper extends StatelessWidget {
  const RoleBasedHomeWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is Authenticated) {
          final user = state.user;

          // ✅ FIXED: Only ADMIN sees admin screens, MANAGER sees employee screens
          if (user.role == 'ADMIN') {
            // Show Admin Home with Admin Bottom Navigation
            return const AdminHomeWrapper();
          }

          // Show Employee Home with Employee Bottom Navigation (for both EMPLOYEE and MANAGER)
          return const HomeScreen();
        }

        // If not authenticated, this shouldn't happen
        // but just in case, return empty container
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}