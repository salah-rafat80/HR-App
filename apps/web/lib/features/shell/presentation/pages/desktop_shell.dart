import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hr_core/core/enums/role_enums.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'dart:ui' as ui;
import '../../../../core/bloc/session_cubit.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/theme/app_colors.dart';

class DesktopShell extends StatelessWidget {
  final Widget child;
  const DesktopShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      body: Row(
        children: [
          const _Sidebar(),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                bottomLeft: Radius.circular(24),
              ),
              child: Scaffold(
                backgroundColor: Theme.of(context).colorScheme.surface,
                body: Column(
                  children: [
                    const _TopBar(),
                    Expanded(
                      child: ClipRRect(
                        child: child,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar();

  @override
  Widget build(BuildContext context) {
    final role = context.watch<SessionCubit>().state;
    if (role == null) return const SizedBox.shrink();

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
                    _NavItem(icon: Iconsax.home_2, activeIcon: Iconsax.home_2_copy, label: 'Dashboard', route: AppRoutes.dashboard, isWide: isWide),
                    _NavItem(icon: Iconsax.tick_circle, activeIcon: Iconsax.tick_circle_copy, label: 'Approvals', route: AppRoutes.approvals, isWide: isWide),
                    _NavItem(icon: Iconsax.chart_2, activeIcon: Iconsax.chart_2_copy, label: 'KPI Overview', route: AppRoutes.teamKpi, isWide: isWide),
                  ],
                  if (role == UserRole.manager || role == UserRole.hrAdmin || role == UserRole.superAdmin) ...[
                    const SizedBox(height: 16),
                    if (isWide) const Padding(padding: EdgeInsets.only(left: 12, bottom: 8), child: Text('RECRUITMENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))),
                    _NavItem(icon: Iconsax.people, activeIcon: Iconsax.people_copy, label: 'Pipeline', route: AppRoutes.recruitment, isWide: isWide),
                  ],
                  if (role == UserRole.hrAdmin || role == UserRole.superAdmin) ...[
                    const SizedBox(height: 16),
                    if (isWide) const Padding(padding: EdgeInsets.only(left: 12, bottom: 8), child: Text('OPERATIONS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))),
                    _NavItem(icon: Iconsax.wallet_2, activeIcon: Iconsax.wallet_2_copy, label: 'Payroll Runs', route: AppRoutes.payroll, isWide: isWide),
                    _NavItem(icon: Iconsax.user_add, activeIcon: Iconsax.user_add_copy, label: 'Onboarding', route: AppRoutes.onboarding, isWide: isWide),
                    _NavItem(icon: Iconsax.user_minus, activeIcon: Iconsax.user_minus_copy, label: 'Offboarding', route: AppRoutes.offboarding, isWide: isWide),
                    _NavItem(icon: Iconsax.medal_star, activeIcon: Iconsax.medal_star_copy, label: 'Appraisals', route: AppRoutes.newAppraisal, isWide: isWide),
                    _NavItem(icon: Iconsax.setting_2, activeIcon: Iconsax.setting_2_copy, label: 'System Config', route: AppRoutes.systemConfig, isWide: isWide),
                  ],
                  if (role == UserRole.cLevel) ...[
                    _NavItem(icon: Iconsax.chart_square, activeIcon: Iconsax.chart_square_copy, label: 'Executive', route: AppRoutes.executiveDashboard, isWide: isWide),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: _NavItem(
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

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
  final bool isWide;
  final VoidCallback? onTap;

  const _NavItem({
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
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: isWide ? 16 : 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: isWide ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                child: Icon(
                  isSelected ? activeIcon : icon,
                  key: ValueKey(isSelected),
                  color: isSelected ? AppColors.primary : colorScheme.onSurfaceVariant,
                  size: 24,
                ),
              ),
              if (isWide) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? AppColors.primary : colorScheme.onSurface,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    final role = context.watch<SessionCubit>().state;
    final isDark = context.watch<ThemeCubit>().state == ThemeMode.dark;
    final colorScheme = Theme.of(context).colorScheme;
    
    return ClipRRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.8),
            border: Border(bottom: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3))),
          ),
          child: Row(
            children: [
              Text(
                'HR Portal',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  role?.name.toUpperCase() ?? '',
                  style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ),
              const SizedBox(width: 16),
              _buildIconButton(
                context,
                isDark ? Iconsax.sun : Iconsax.moon,
                onTap: () => context.read<ThemeCubit>().toggleTheme(),
              ),
              const SizedBox(width: 12),
              _buildIconButton(context, Iconsax.notification, onTap: () {}),
              const SizedBox(width: 16),
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Icon(Iconsax.user, color: AppColors.primary, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(BuildContext context, IconData icon, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}
