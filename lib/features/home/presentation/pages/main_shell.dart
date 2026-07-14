import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/bloc/session_cubit.dart';
import '../../../../core/enums/role_enums.dart';
import '../../../../core/di/injection.dart';

class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final role = getIt<SessionCubit>().state;
    final showTeamTab = role == UserRole.teamLead || role == UserRole.manager;
    final showAdminTab = role == UserRole.hrAdmin || role == UserRole.superAdmin;
    
    final items = [
      BottomNavigationBarItem(icon: const Icon(Icons.home), label: 'home_title'.tr()),
      BottomNavigationBarItem(icon: const Icon(Icons.access_time), label: 'attendance_title'.tr()),
      BottomNavigationBarItem(icon: const Icon(Icons.calendar_month), label: 'leave_title'.tr()),
      BottomNavigationBarItem(icon: const Icon(Icons.grid_view), label: 'modules'.tr()),
      if (showTeamTab) BottomNavigationBarItem(icon: const Icon(Icons.group), label: 'Team'),
      if (showAdminTab) BottomNavigationBarItem(icon: const Icon(Icons.admin_panel_settings), label: 'Admin'),
      BottomNavigationBarItem(icon: const Icon(Icons.person), label: 'profile'.tr()),
    ];

    return SafeArea(
      child: Scaffold(
        body: child,
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          currentIndex: _calculateSelectedIndex(context, showTeamTab, showAdminTab),
          onTap: (index) => _onItemTapped(index, context, showTeamTab, showAdminTab),
          items: items,
        ),
      ),
    );
  }

  static int _calculateSelectedIndex(BuildContext context, bool showTeamTab, bool showAdminTab) {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/attendance')) return 1;
    if (location.startsWith('/leave')) return 2;
    if (location.startsWith('/modules')) return 3;
    if (showTeamTab && location.startsWith('/team')) return 4;
    if (showAdminTab && location.startsWith('/admin')) return 4;
    if (location.startsWith('/profile')) return (showTeamTab || showAdminTab) ? 5 : 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context, bool showTeamTab, bool showAdminTab) {
    if (index == 0) {
      context.go('/home');
    } else if (index == 1) {
      context.go('/attendance');
    } else if (index == 2) {
      context.go('/leave');
    } else if (index == 3) {
      context.go('/modules');
    } else if (showTeamTab && index == 4) {
      context.go('/team');
    } else if (showAdminTab && index == 4) {
      context.go('/admin');
    } else if (((showTeamTab || showAdminTab) && index == 5) || (!(showTeamTab || showAdminTab) && index == 4)) {
      context.go('/profile');
    }
  }
}
