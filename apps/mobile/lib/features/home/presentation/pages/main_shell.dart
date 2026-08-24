import 'package:flutter/material.dart';
import 'package:hr_app_demo/core/theme/app_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/floating_nav_bar.dart';
import '../../../../core/services/fcm_service.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/bloc/session_cubit.dart';
import '../bloc/home_cubit.dart';
import '../../../attendance/presentation/bloc/attendance_cubit.dart';
import '../../../leave/presentation/bloc/leave_cubit.dart';

class MainShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

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
    context.watch<ThemeCubit>();
    final locale = context.locale;

    return Scaffold(
      body: KeyedSubtree(
        key: ValueKey('${AppColors.isDarkMode}_${locale.languageCode}'),
        child: widget.navigationShell,
      ),
      bottomNavigationBar: SafeArea(
        child: FloatingNavBar(
          items: _getNavItems(context),
          selectedIndex: widget.navigationShell.currentIndex,
          onItemSelected: (index) => _onItemTapped(index),
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
    _refreshActiveTab(index);
  }

  void _refreshActiveTab(int index) {
    try {
      switch (index) {
        case 0:
          getIt<HomeCubit>().loadDashboard();
          break;
        case 1:
          getIt<AttendanceCubit>().loadAttendanceData();
          break;
        case 2:
          getIt<LeaveCubit>().loadData();
          break;
        case 4:
          getIt<SessionCubit>().checkStoredSession();
          break;
      }
    } catch (_) {}
  }
}

