import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/widgets/app_card.dart';

class ProfileHeaderCard extends StatelessWidget {
  final String name;
  final String title;
  final String employeeCode;
  final String department;

  const ProfileHeaderCard({
    super.key,
    required this.name,
    required this.title,
    required this.employeeCode,
    required this.department,
  });

  String _getInitials(String input) {
    if (input.trim().isEmpty) return 'U';
    final parts = input.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return input[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.all(20.w),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: CircleAvatar(
              radius: 44.w,
              backgroundColor: Theme.of(context).cardColor,
              child: Text(
                _getInitials(name),
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            name,
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12.h),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8.w,
            children: [
              Chip(
                avatar: const Icon(AppIcons.profile, size: 16),
                label: Text(
                  employeeCode,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                side: BorderSide.none,
              ),
              Chip(
                avatar: const Icon(AppIcons.modules, size: 16),
                label: Text(
                  department,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
                side: BorderSide.none,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
