import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/app_routes.dart';

class HomeQuickActions extends StatelessWidget {
  const HomeQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ActionIcon(icon: Icons.access_time, label: 'clock_in'.tr(), onTap: () => context.go(AppRoutes.attendance)),
          _ActionIcon(icon: Icons.event_note, label: 'apply_leave'.tr(), onTap: () => context.go(AppRoutes.leave)),
          _ActionIcon(icon: Icons.analytics, label: 'my_kpis'.tr(), onTap: () => context.push(AppRoutes.kpi)),
          _ActionIcon(icon: Icons.track_changes, label: 'my_goals'.tr(), onTap: () => context.push(AppRoutes.appraisal)),
        ],
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionIcon({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 28.w,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Icon(icon, color: AppColors.primary, size: 28.w),
          ),
          SizedBox(height: 8.h),
          Text(label, style: TextStyle(fontSize: 12.sp, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
