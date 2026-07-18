import 'package:flutter/material.dart';
import 'package:hr_app_demo/core/widgets/app_custom_bar.dart';
import 'package:hr_app_demo/core/theme/app_icons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';

class ModulesScreen extends StatelessWidget {
  const ModulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final modules = [
      {'title': 'attendance_title', 'icon': AppIcons.attendance, 'route': AppRoutes.attendance},
      {'title': 'leave_management', 'icon': AppIcons.leave, 'route': AppRoutes.leave},
      {'title': 'my_kpis', 'icon': AppIcons.kpi, 'route': AppRoutes.kpi},
      {'title': 'appraisal_module', 'icon': AppIcons.appraisal, 'route': AppRoutes.appraisal},
      {'title': 'payroll_title', 'icon': AppIcons.payroll, 'route': AppRoutes.payroll},
      {'title': 'training_title', 'icon': AppIcons.training, 'route': AppRoutes.training},
      {'title': 'communication_hub', 'icon': AppIcons.communication, 'route': AppRoutes.communication},
      {'title': 'Engagement', 'icon': AppIcons.engagement, 'route': AppRoutes.engagement},
      {'title': 'Org Chart', 'icon': AppIcons.orgChart, 'route': AppRoutes.orgChart},
    ];

    return Scaffold(
      
        appBar: AppCustomBar(automaticallyImplyLeading: false, title: Text('modules'.tr())),
      body: GridView.builder(
        padding: EdgeInsets.all(16.w),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 16.w,
          mainAxisSpacing: 16.h,
          childAspectRatio: 0.8,
        ),
        itemCount: modules.length,
        itemBuilder: (context, index) {
          final mod = modules[index];
          return InkWell(
            onTap: () {
              final route = mod['route'] as String;
              if (route == AppRoutes.attendance || route == AppRoutes.leave) {
                context.go(route);
              } else {
                context.push(route);
              }
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 30.w,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Icon(mod['icon'] as IconData, color: AppColors.primary, size: 28.w),
                ),
                SizedBox(height: 8.h),
                Text(
                  (mod['title'] as String).tr(),
                  style: TextStyle(fontSize: 12.sp),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
