import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hr_core/core/enums/role_enums.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../../core/bloc/session_cubit.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final sessionState = context.watch<SessionCubit>().state;
    if (!sessionState.isAuthenticated) return const SizedBox.shrink();
    final role = sessionState.role;

    final isWide = MediaQuery.of(context).size.width > 900;
    final width = isWide ? 260.0 : 88.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: width,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(5, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 32),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: isWide ? 48 : 36,
            height: isWide ? 48 : 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Iconsax.activity, color: AppColors.primary),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (role != UserRole.cLevel) ...[
                    NavItem(
                      icon: Iconsax.home_2,
                      activeIcon: Iconsax.home_2_copy,
                      label: 'Dashboard',
                      route: AppRoutes.dashboard,
                      isWide: isWide,
                    ),
                    NavItem(
                      icon: Iconsax.tick_circle,
                      activeIcon: Iconsax.tick_circle_copy,
                      label: 'Approvals',
                      route: AppRoutes.approvals,
                      isWide: isWide,
                    ),
                    if (role == UserRole.teamLead ||
                        role == UserRole.hrAdmin ||
                        role == UserRole.superAdmin)
                      NavItem(
                        icon: Icons.timer_outlined,
                        activeIcon: Icons.timer,
                        label: 'Overtime',
                        route: AppRoutes.overtimeApprovals,
                        isWide: isWide,
                      ),
                    NavItem(
                      icon: Iconsax.chart_2,
                      activeIcon: Iconsax.chart_2_copy,
                      label: 'KPI Overview',
                      route: AppRoutes.teamKpi,
                      isWide: isWide,
                    ),
                  ],
                  if (role == UserRole.manager ||
                      role == UserRole.hrAdmin ||
                      role == UserRole.superAdmin) ...[
                    const SizedBox(height: 16),
                    if (isWide)
                      const Padding(
                        padding: EdgeInsets.only(left: 12, bottom: 8),
                        child: Text(
                          'RECRUITMENT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    NavItem(
                      icon: Iconsax.people,
                      activeIcon: Iconsax.people_copy,
                      label: 'Pipeline',
                      route: AppRoutes.recruitment,
                      isWide: isWide,
                    ),
                  ],
                  if (role == UserRole.hrAdmin ||
                      role == UserRole.superAdmin) ...[
                    const SizedBox(height: 16),
                    if (isWide)
                      const Padding(
                        padding: EdgeInsets.only(left: 12, bottom: 8),
                        child: Text(
                          'OPERATIONS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    NavItem(
                      icon: Iconsax.wallet_2,
                      activeIcon: Iconsax.wallet_2_copy,
                      label: 'Payroll Runs',
                      route: AppRoutes.payroll,
                      isWide: isWide,
                    ),
                    NavItem(
                      icon: Icons.assessment_outlined,
                      activeIcon: Icons.assessment,
                      label: 'HR Reports',
                      route: AppRoutes.hrReports,
                      isWide: isWide,
                    ),
                    NavItem(
                      icon: Iconsax.user_add,
                      activeIcon: Iconsax.user_add_copy,
                      label: 'Onboarding',
                      route: AppRoutes.onboarding,
                      isWide: isWide,
                    ),
                    NavItem(
                      icon: Iconsax.user_minus,
                      activeIcon: Iconsax.user_minus_copy,
                      label: 'Offboarding',
                      route: AppRoutes.offboarding,
                      isWide: isWide,
                    ),
                    NavItem(
                      icon: Iconsax.medal_star,
                      activeIcon: Iconsax.medal_star_copy,
                      label: 'Appraisals',
                      route: AppRoutes.newAppraisal,
                      isWide: isWide,
                    ),
                    NavItem(
                      icon: Iconsax.setting_2,
                      activeIcon: Iconsax.setting_2_copy,
                      label: 'System Config',
                      route: AppRoutes.systemConfig,
                      isWide: isWide,
                    ),
                  ],
                  if (role == UserRole.cLevel) ...[
                    NavItem(
                      icon: Iconsax.chart_square,
                      activeIcon: Iconsax.chart_square_copy,
                      label: 'Executive',
                      route: AppRoutes.executiveDashboard,
                      isWide: isWide,
                    ),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: NavItem(
              icon: Iconsax.logout,
              activeIcon: Iconsax.logout,
              label: 'Logout',
              route: AppRoutes.login,
              isWide: isWide,
              onTap: () {
                context.read<SessionCubit>().logout();
                context.go(AppRoutes.login);
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
  final bool isWide;
  final VoidCallback? onTap;

  const NavItem({
    super.key,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
    required this.isWide,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final isSelected = location.startsWith(route) && route != AppRoutes.login;
    final colorScheme = Theme.of(context).colorScheme;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap ?? () => context.go(route),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          margin: const EdgeInsets.only(bottom: 8),
          padding: EdgeInsets.symmetric(
            vertical: 12,
            horizontal: isWide ? 16 : 12,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: isWide
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Icon(
                  isSelected ? activeIcon : icon,
                  key: ValueKey(isSelected),
                  color: isSelected
                      ? AppColors.primary
                      : colorScheme.onSurfaceVariant,
                  size: 24,
                ),
              ),
              if (isWide) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.primary
                          : colorScheme.onSurface,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
