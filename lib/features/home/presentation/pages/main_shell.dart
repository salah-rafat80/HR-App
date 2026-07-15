import 'package:flutter/material.dart';
import 'package:hr_app_demo/core/theme/app_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/bloc/session_cubit.dart';
import '../../../../core/enums/role_enums.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/theme_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/widgets/floating_nav_bar.dart';

class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final role = getIt<SessionCubit>().state;
    final showTeamTab = role == UserRole.teamLead || role == UserRole.manager;
    final showAdminTab = role == UserRole.hrAdmin || role == UserRole.superAdmin;
    
    final items = [
      NavItem(AppIcons.home, AppIcons.homeActive, 'home_title'.tr()),
      NavItem(AppIcons.attendance, AppIcons.attendanceActive, 'attendance_title'.tr()),
      NavItem(AppIcons.leave, AppIcons.leaveActive, 'leave_title'.tr()),
      NavItem(AppIcons.modules, AppIcons.modulesActive, 'modules'.tr()),
      if (showTeamTab) NavItem(AppIcons.team, AppIcons.teamActive, 'Team'),
      if (showAdminTab) NavItem(AppIcons.admin, AppIcons.adminActive, 'Admin'),
      NavItem(AppIcons.profile, AppIcons.profileActive, 'profile'.tr()),
    ];

    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, theme) {
        return Scaffold(
          body: child,
          bottomNavigationBar: SafeArea(
            child: FloatingNavBar(
              items: items,
              selectedIndex: _calculateSelectedIndex(context, showTeamTab, showAdminTab),
              onItemSelected: (index) => _onItemTapped(index, context, showTeamTab, showAdminTab),
            ),
          ),
        );
      }
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
