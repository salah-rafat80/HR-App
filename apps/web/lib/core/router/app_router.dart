import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_routes.dart';
import '../../features/auth/presentation/pages/login_screen.dart';
import '../../features/shell/presentation/pages/desktop_shell.dart';
import '../../features/shell/presentation/pages/dashboard_screen.dart';
import '../../features/approvals/presentation/pages/approvals_screen.dart';
import '../../features/team_kpi/presentation/pages/team_kpi_screen.dart';
import '../../features/payroll/presentation/pages/payroll_screen.dart';
import '../../features/recruitment/presentation/pages/recruitment_screen.dart';
import '../../features/onboarding/presentation/pages/onboarding_screen.dart';
import '../../features/offboarding/presentation/pages/offboarding_screen.dart';
import '../../features/system_config/presentation/pages/system_config_screen.dart';
import '../../features/appraisal/presentation/pages/appraisal_screen.dart';
import '../../features/executive/presentation/pages/executive_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

class AppRouter {
  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.login,
    routes: [
      GoRoute(
        path: AppRoutes.login,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return DesktopShell(child: child);
        },
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            parentNavigatorKey: _shellNavigatorKey,
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.approvals,
            parentNavigatorKey: _shellNavigatorKey,
            builder: (context, state) => const ApprovalsScreen(),
          ),
          GoRoute(
            path: AppRoutes.teamKpi,
            parentNavigatorKey: _shellNavigatorKey,
            builder: (context, state) => const TeamKpiScreen(),
          ),
          GoRoute(
            path: AppRoutes.payroll,
            parentNavigatorKey: _shellNavigatorKey,
            builder: (context, state) => const PayrollScreen(),
          ),
          GoRoute(
            path: AppRoutes.recruitment,
            parentNavigatorKey: _shellNavigatorKey,
            builder: (context, state) => const RecruitmentScreen(),
          ),
          GoRoute(
            path: AppRoutes.onboarding,
            parentNavigatorKey: _shellNavigatorKey,
            builder: (context, state) => const OnboardingScreen(),
          ),
          GoRoute(
            path: AppRoutes.offboarding,
            parentNavigatorKey: _shellNavigatorKey,
            builder: (context, state) => const OffboardingScreen(),
          ),
          GoRoute(
            path: AppRoutes.systemConfig,
            parentNavigatorKey: _shellNavigatorKey,
            builder: (context, state) => const SystemConfigScreen(),
          ),
          GoRoute(
            path: AppRoutes.newAppraisal,
            parentNavigatorKey: _shellNavigatorKey,
            builder: (context, state) => const AppraisalScreen(),
          ),
          GoRoute(
            path: AppRoutes.executiveDashboard,
            parentNavigatorKey: _shellNavigatorKey,
            builder: (context, state) => const ExecutiveScreen(),
          ),
        ],
      ),
    ],
  );
}
