import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/bloc/session_cubit.dart';
import '../../../../core/enums/role_enums.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/di/injection.dart';

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
              Icon(Icons.admin_panel_settings, size: 64.w, color: AppColors.primary),
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
                      icon: Icons.person,
                      role: UserRole.employee,
                      onTap: () => _selectRole(context, UserRole.employee),
                    ),
                    _RoleCard(
                      title: 'Team Lead',
                      icon: Icons.group,
                      role: UserRole.teamLead,
                      onTap: () => _selectRole(context, UserRole.teamLead),
                    ),
                    _RoleCard(
                      title: 'Manager',
                      icon: Icons.manage_accounts,
                      role: UserRole.manager,
                      onTap: () => _selectRole(context, UserRole.manager),
                    ),
                    _RoleCard(
                      title: 'HR Admin',
                      icon: Icons.work,
                      role: UserRole.hrAdmin,
                      onTap: () => _selectRole(context, UserRole.hrAdmin),
                    ),
                    _RoleCard(
                      title: 'Super Admin',
                      icon: Icons.security,
                      role: UserRole.superAdmin,
                      onTap: () => _selectRole(context, UserRole.superAdmin),
                    ),
                    _RoleCard(
                      title: 'C-Level Executive',
                      icon: Icons.insights,
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
    context.go(AppRoutes.home);
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
    return Card(
      margin: EdgeInsets.only(bottom: 16.h),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: ListTile(
        onTap: onTap,
        contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(title, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      ),
    );
  }
}
