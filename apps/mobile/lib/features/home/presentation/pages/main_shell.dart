import 'package:flutter/material.dart';
import 'package:hr_app_demo/core/theme/app_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/widgets/floating_nav_bar.dart';
import '../../../../core/services/fcm_service.dart';
import '../../../../core/router/app_routes.dart';

class MainShell extends StatefulWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FcmService.instance.consumePendingNotification(context);
      }
    });
  }

  List<NavItem> _getNavItems(BuildContext context) {
    return [
      NavItem(AppIcons.home, AppIcons.homeActive, 'home_title'.tr()),
      NavItem(AppIcons.attendance, AppIcons.attendanceActive, 'attendance_title'.tr()),
      NavItem(AppIcons.leave, AppIcons.leaveActive, 'leave_title'.tr()),
      NavItem(AppIcons.modules, AppIcons.modulesActive, 'modules'.tr()),
      NavItem(AppIcons.profile, AppIcons.profileActive, 'profile'.tr()),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, theme) {
        return Scaffold(
          body: widget.child,
          bottomNavigationBar: SafeArea(
            child: FloatingNavBar(
              items: _getNavItems(context),
              selectedIndex: _calculateSelectedIndex(context),
              onItemSelected: (index) => _onItemTapped(index, context),
            ),
          ),
        );
      },
    );
  }

  static int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(AppRoutes.home)) return 0;
    if (location.startsWith(AppRoutes.attendance)) return 1;
    if (location.startsWith(AppRoutes.leave)) return 2;
    if (location.startsWith(AppRoutes.modules)) return 3;
    if (location.startsWith(AppRoutes.profile)) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    if (index == 0) {
      context.go(AppRoutes.home);
    } else if (index == 1) {
      context.go(AppRoutes.attendance);
    } else if (index == 2) {
      context.go(AppRoutes.leave);
    } else if (index == 3) {
      context.go(AppRoutes.modules);
    } else if (index == 4) {
      context.go(AppRoutes.profile);
    }
  }
}

