import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hr_core/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:hr_core/features/admin/domain/repositories/hr_report_repository.dart';

import 'app_routes.dart';
import '../di/injection.dart';
import '../../features/auth/presentation/pages/login_screen.dart';
import '../../features/shell/presentation/pages/desktop_shell.dart';
import '../../features/shell/presentation/pages/dashboard_screen.dart';
import '../../features/approvals/presentation/pages/approvals_screen.dart';
import '../../features/approvals/presentation/pages/overtime_approvals_screen.dart';
import '../../features/approvals/presentation/bloc/overtime_approvals_cubit.dart';
import '../../features/reports/presentation/pages/hr_reports_screen.dart';
import '../../features/reports/presentation/bloc/hr_reports_cubit.dart';
import '../../features/team_kpi/presentation/pages/team_kpi_screen.dart';
import '../../features/payroll/presentation/pages/payroll_screen.dart';
import '../../features/recruitment/presentation/pages/recruitment_screen.dart';
import '../../features/onboarding/presentation/pages/onboarding_screen.dart';
import '../../features/offboarding/presentation/pages/offboarding_screen.dart';
import '../../features/system_config/presentation/pages/system_config_screen.dart';
import '../../features/appraisal/presentation/pages/appraisal_screen.dart';
import '../../features/executive/presentation/pages/executive_screen.dart';
import '../../features/leave_management/presentation/pages/leave_management_screen.dart';
import '../bloc/session_cubit.dart';

import 'package:hr_core/core/enums/role_enums.dart';

import '../../features/auth/presentation/pages/splash_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>();

String _firstRouteForRole(UserRole role) {
  switch (role) {
    case UserRole.teamLead:
    case UserRole.manager:
      return AppRoutes.overtimeApprovals;
    case UserRole.hr:
    case UserRole.hrAdmin:
    case UserRole.superAdmin:
      return AppRoutes.hrReports;
    case UserRole.employee:
      return AppRoutes.dashboard;
  }
}

class AppRouter {
  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final sessionState = context.read<SessionCubit>().state;
      final isSplash = state.matchedLocation == AppRoutes.splash;
      final isLogin = state.matchedLocation == AppRoutes.login;

      // Allow splash to perform session bootstrap
      if (isSplash) {
        return null;
      }

      // If not logged in and trying to access protected route, redirect to login
      if (!sessionState.isAuthenticated && !isLogin) {
        return AppRoutes.login;
      }

      // If logged in and on login page, redirect to role-appropriate first section
      if (sessionState.isAuthenticated && isLogin) {
        return _firstRouteForRole(sessionState.role ?? UserRole.employee);
      }

      // Role Protection Guards
      if (sessionState.isAuthenticated) {
        final role = sessionState.role ?? UserRole.employee;
        final loc = state.matchedLocation;

        // Leave Management is HR only
        final isHrRole = role == UserRole.hr ||
            role == UserRole.hrAdmin ||
            role == UserRole.superAdmin;
        if (loc == AppRoutes.leaveManagement && !isHrRole) {
          return _firstRouteForRole(role);
        }

        // Employees cannot access overtime approvals, hr reports, or system config
        if (role == UserRole.employee) {
          if (loc == AppRoutes.overtimeApprovals ||
              loc == AppRoutes.hrReports ||
              loc == AppRoutes.systemConfig) {
            return AppRoutes.dashboard;
          }
        }

        // Team Leads cannot access HR reports or System Config
        if (role == UserRole.teamLead) {
          if (loc == AppRoutes.hrReports || loc == AppRoutes.systemConfig) {
            return AppRoutes.overtimeApprovals;
          }
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const WebSplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => DesktopShell(child: child),
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
            path: AppRoutes.overtimeApprovals,
            parentNavigatorKey: _shellNavigatorKey,
            builder: (context, state) {
              final role =
                  context.read<SessionCubit>().state.role ?? UserRole.employee;
              return BlocProvider(
                create: (_) => OvertimeApprovalsCubit(
                  getIt<AttendanceRepository>(),
                ),
                child: OvertimeApprovalsScreen(userRole: role),
              );
            },
          ),
          GoRoute(
            path: AppRoutes.hrReports,
            parentNavigatorKey: _shellNavigatorKey,
            builder: (context, state) => BlocProvider(
              create: (_) => HrReportsCubit(getIt<HrReportRepository>()),
              child: const HrReportsScreen(),
            ),
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
          GoRoute(
            path: AppRoutes.leaveManagement,
            parentNavigatorKey: _shellNavigatorKey,
            builder: (context, state) => const LeaveManagementScreen(),
          ),
        ],
      ),
    ],
  );
}
