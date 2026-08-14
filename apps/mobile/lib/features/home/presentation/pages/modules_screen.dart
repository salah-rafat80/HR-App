import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hr_app_demo/core/widgets/app_custom_bar.dart';
import 'package:hr_app_demo/core/theme/app_icons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/bloc/session_cubit.dart';
import '../../../../core/theme/app_colors.dart';

class ModuleItem {
  final String titleKey;
  final IconData icon;
  final String route;

  const ModuleItem({
    required this.titleKey,
    required this.icon,
    required this.route,
  });
}

class ModulesScreen extends StatelessWidget {
  static const List<ModuleItem> _modules = [
    ModuleItem(
      titleKey: 'attendance_title',
      icon: AppIcons.attendance,
      route: AppRoutes.attendance,
    ),
    ModuleItem(
      titleKey: 'leave_management',
      icon: AppIcons.leave,
      route: AppRoutes.leave,
    ),
    ModuleItem(titleKey: 'my_kpis', icon: AppIcons.kpi, route: AppRoutes.kpi),
    ModuleItem(
      titleKey: 'appraisal_module',
      icon: AppIcons.appraisal,
      route: AppRoutes.appraisal,
    ),
    ModuleItem(
      titleKey: 'payroll_title',
      icon: AppIcons.payroll,
      route: AppRoutes.payroll,
    ),
    ModuleItem(
      titleKey: 'training_title',
      icon: AppIcons.training,
      route: AppRoutes.training,
    ),
    ModuleItem(
      titleKey: 'communication_hub',
      icon: AppIcons.communication,
      route: AppRoutes.communication,
    ),
    ModuleItem(
      titleKey: 'Engagement',
      icon: AppIcons.engagement,
      route: AppRoutes.engagement,
    ),
    ModuleItem(
      titleKey: 'Org Chart',
      icon: AppIcons.orgChart,
      route: AppRoutes.orgChart,
    ),
  ];

  const ModulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppCustomBar(
        automaticallyImplyLeading: false,
        title: Text('modules'.tr()),
      ),
      body: Builder(
        builder: (context) {
          final role = context.watch<SessionCubit>().state.role;
          final canApproveOvertime =
              role == 'team_lead' ||
              role == 'hr' ||
              role == 'hrAdmin' ||
              role == 'superAdmin';
          final modules = [
            ..._modules,
            if (canApproveOvertime)
              const ModuleItem(
                titleKey: 'Overtime approvals',
                icon: Icons.approval_outlined,
                route: AppRoutes.overtimeApprovals,
              ),
          ];

          return GridView.builder(
            padding: EdgeInsets.all(16.w),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16.w,
              mainAxisSpacing: 16.h,
              childAspectRatio: 0.8,
            ),
            itemCount: modules.length,
            itemBuilder: (context, index) {
              final module = modules[index];
              return InkWell(
                onTap: () {
                  if (module.route == AppRoutes.attendance ||
                      module.route == AppRoutes.leave) {
                    context.go(module.route);
                  } else {
                    context.push(module.route);
                  }
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 30.w,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: Icon(
                        module.icon,
                        color: AppColors.primary,
                        size: 28.w,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      module.titleKey.tr(),
                      style: TextStyle(fontSize: 12.sp),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
