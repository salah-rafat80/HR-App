import 'package:flutter/material.dart';
import 'package:hr_app_demo/core/theme/app_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/theme_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/widgets/floating_nav_bar.dart';

class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final items = [
      NavItem(AppIcons.home, AppIcons.homeActive, 'home_title'.tr()),
      NavItem(AppIcons.attendance, AppIcons.attendanceActive, 'attendance_title'.tr()),
      NavItem(AppIcons.leave, AppIcons.leaveActive, 'leave_title'.tr()),
      NavItem(AppIcons.modules, AppIcons.modulesActive, 'modules'.tr()),
      NavItem(AppIcons.profile, AppIcons.profileActive, 'profile'.tr()),
    ];

    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, theme) {
        return Scaffold(
          body: child,
          bottomNavigationBar: SafeArea(
            child: FloatingNavBar(
              items: items,
              selectedIndex: _calculateSelectedIndex(context),
              onItemSelected: (index) => _onItemTapped(index, context),
            ),
          ),
        );
      }
    );
  }

  static int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/attendance')) return 1;
    if (location.startsWith('/leave')) return 2;
    if (location.startsWith('/modules')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    if (index == 0) {
      context.go('/home');
    } else if (index == 1) {
      context.go('/attendance');
    } else if (index == 2) {
      context.go('/leave');
    } else if (index == 3) {
      context.go('/modules');
    } else if (index == 4) {
      context.go('/profile');
    }
  }
}
