import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_routes.dart';
import '../../features/auth/presentation/pages/splash_screen.dart';
import '../../features/auth/presentation/pages/login_screen.dart';
import '../../features/auth/presentation/pages/role_selection_screen.dart';
import '../../features/home/presentation/pages/main_shell.dart';
import '../../features/team/presentation/pages/team_screen.dart';
import '../../features/admin/presentation/pages/admin_screen.dart';
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
  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.roleSelection,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const RoleSelectionScreen(),
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
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.attendance,
            parentNavigatorKey: _shellNavigatorKey,
            builder: (context, state) => const AttendanceScreen(),
          ),
          GoRoute(
            path: AppRoutes.leave,
            parentNavigatorKey: _shellNavigatorKey,
            builder: (context, state) => const LeaveScreen(),
          ),
          GoRoute(
            path: AppRoutes.modules,
            parentNavigatorKey: _shellNavigatorKey,
            builder: (context, state) => const ModulesScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            parentNavigatorKey: _shellNavigatorKey,
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: AppRoutes.team,
            parentNavigatorKey: _shellNavigatorKey,
            builder: (context, state) => const TeamScreen(),
          ),
          GoRoute(
            path: AppRoutes.admin,
            parentNavigatorKey: _shellNavigatorKey,
            builder: (context, state) => const AdminScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/coming-soon',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ComingSoonScreen(),
      ),
      GoRoute(
        path: AppRoutes.kpi,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const KpiScreen(),
      ),
      GoRoute(
        path: AppRoutes.appraisal,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AppraisalScreen(),
      ),
      GoRoute(
        path: AppRoutes.payroll,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PayrollScreen(),
      ),
      GoRoute(
        path: AppRoutes.training,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const TrainingScreen(),
      ),
      GoRoute(
        path: AppRoutes.communication,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CommunicationScreen(),
      ),
    ],
  );
}
