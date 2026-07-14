import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_routes.dart';
import '../../features/auth/presentation/pages/splash_screen.dart';
import '../../features/auth/presentation/pages/login_screen.dart';
import '../../features/auth/presentation/pages/role_selection_screen.dart';
import '../../features/home/presentation/pages/main_shell.dart';
import '../../features/team/presentation/pages/team_screen.dart';
import '../../features/admin/presentation/pages/admin_screen.dart';
import '../../features/executive/presentation/pages/executive_screen.dart';
import '../../features/home/presentation/pages/home_screen.dart';
import '../../features/attendance/presentation/pages/attendance_screen.dart';
import '../../features/leave/presentation/pages/leave_screen.dart';
import '../../features/home/presentation/pages/modules_screen.dart';
import '../../features/profile/presentation/pages/profile_screen.dart';
import '../widgets/coming_soon_screen.dart';
import '../../features/kpi/presentation/pages/kpi_screen.dart';
import '../../features/appraisal/presentation/pages/appraisal_screen.dart';
import '../../features/payroll/presentation/pages/payroll_screen.dart';
import '../../features/training/presentation/pages/training_screen.dart';
import '../../features/communication/presentation/pages/communication_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

class AppRouter {
  static CustomTransitionPage _fadeTransition(Widget child) {
    return CustomTransitionPage(
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _fadeTransition(const SplashScreen()),
      ),
      GoRoute(
        path: AppRoutes.login,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _fadeTransition(const LoginScreen()),
      ),
      GoRoute(
        path: AppRoutes.roleSelection,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _fadeTransition(const RoleSelectionScreen()),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return MainShell(child: child);
        },
        routes: [
          GoRoute(
            path: AppRoutes.home,
            parentNavigatorKey: _shellNavigatorKey,
            pageBuilder: (context, state) => _fadeTransition(const HomeScreen()),
          ),
          GoRoute(
            path: AppRoutes.attendance,
            parentNavigatorKey: _shellNavigatorKey,
            pageBuilder: (context, state) => _fadeTransition(const AttendanceScreen()),
          ),
          GoRoute(
            path: AppRoutes.leave,
            parentNavigatorKey: _shellNavigatorKey,
            pageBuilder: (context, state) => _fadeTransition(const LeaveScreen()),
          ),
          GoRoute(
            path: AppRoutes.modules,
            parentNavigatorKey: _shellNavigatorKey,
            pageBuilder: (context, state) => _fadeTransition(const ModulesScreen()),
          ),
          GoRoute(
            path: AppRoutes.profile,
            parentNavigatorKey: _shellNavigatorKey,
            pageBuilder: (context, state) => _fadeTransition(const ProfileScreen()),
          ),
          GoRoute(
            path: AppRoutes.team,
            parentNavigatorKey: _shellNavigatorKey,
            pageBuilder: (context, state) => _fadeTransition(const TeamScreen()),
          ),
          GoRoute(
            path: AppRoutes.admin,
            parentNavigatorKey: _shellNavigatorKey,
            pageBuilder: (context, state) => _fadeTransition(const AdminScreen()),
          ),
        ],
      ),
      GoRoute(
        path: '/coming-soon',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _fadeTransition(const ComingSoonScreen()),
      ),
      GoRoute(
        path: AppRoutes.kpi,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _fadeTransition(const KpiScreen()),
      ),
      GoRoute(
        path: AppRoutes.appraisal,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _fadeTransition(const AppraisalScreen()),
      ),
      GoRoute(
        path: AppRoutes.payroll,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _fadeTransition(const PayrollScreen()),
      ),
      GoRoute(
        path: AppRoutes.training,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _fadeTransition(const TrainingScreen()),
      ),
      GoRoute(
        path: AppRoutes.communication,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _fadeTransition(const CommunicationScreen()),
      ),
      GoRoute(
        path: AppRoutes.executive,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _fadeTransition(const ExecutiveScreen()),
      ),
    ],
  );
}
