import 'package:flutter/material.dart';
import 'package:hr_app_demo/core/theme/app_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/bloc/session_cubit.dart';
import '../../../../core/enums/role_enums.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/widgets/app_card.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 40.h),
              Icon(AppIcons.admin, size: 64.w, color: AppColors.primary),
              SizedBox(height: 16.h),
              Text(
                '🎭 Preview as:',
                style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              Text(
                'Select a role to preview the corresponding app experience.',
                style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40.h),
              Expanded(
                child: ListView(
                  children: [
                    _RoleCard(
                      title: 'Employee',
                      icon: AppIcons.profile,
                      role: UserRole.employee,
                      onTap: () => _selectRole(context, UserRole.employee),
                    ),
                    _RoleCard(
                      title: 'Team Lead',
                      icon: AppIcons.team,
                      role: UserRole.teamLead,
                      onTap: () => _selectRole(context, UserRole.teamLead),
                    ),
                    _RoleCard(
                      title: 'Manager',
                      icon: AppIcons.admin,
                      role: UserRole.manager,
                      onTap: () => _selectRole(context, UserRole.manager),
                    ),
                    _RoleCard(
                      title: 'HR Admin',
                      icon: AppIcons.profile,
                      role: UserRole.hrAdmin,
                      onTap: () => _selectRole(context, UserRole.hrAdmin),
                    ),
                    _RoleCard(
                      title: 'Super Admin',
                      icon: AppIcons.admin,
                      role: UserRole.superAdmin,
                      onTap: () => _selectRole(context, UserRole.superAdmin),
                    ),
                    _RoleCard(
                      title: 'C-Level Executive',
                      icon: AppIcons.kpi,
                      role: UserRole.cLevel,
                      onTap: () => _selectRole(context, UserRole.cLevel),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectRole(BuildContext context, UserRole role) {
    getIt<SessionCubit>().setRole(role);
    if (role == UserRole.cLevel) {
      context.go(AppRoutes.executive);
    } else {
      context.go(AppRoutes.home);
    }
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final UserRole role;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.icon,
    required this.role,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: EdgeInsets.only(bottom: 16.h),
      child: ListTile(
        onTap: onTap,
        contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(title, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600)),
        trailing: Icon(AppIcons.back, color: AppColors.textSecondary),
      ),
    );
  }
}
