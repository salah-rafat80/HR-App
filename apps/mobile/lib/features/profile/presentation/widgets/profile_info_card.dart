import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';

class ProfileInfoCard extends StatelessWidget {
  final String email;
  final String employeeCode;
  final String department;
  final String roleName;

  const ProfileInfoCard({
    super.key,
    required this.email,
    required this.employeeCode,
    required this.department,
    required this.roleName,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'personal_info'.tr(),
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: Text('email'.tr()),
            subtitle: Text(email),
            dense: true,
          ),
          ListTile(
            leading: const Icon(Icons.badge_outlined),
            title: Text('employee_code'.tr()),
            subtitle: Text(employeeCode),
            dense: true,
          ),
          ListTile(
            leading: const Icon(Icons.business_outlined),
            title: Text('department'.tr()),
            subtitle: Text(department),
            dense: true,
          ),
          ListTile(
            leading: const Icon(Icons.admin_panel_settings_outlined),
            title: Text('role'.tr()),
            subtitle: Text(roleName.tr()),
            dense: true,
          ),
        ],
      ),
    );
  }
}
