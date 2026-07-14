import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false, title: Text('profile'.tr())),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          CircleAvatar(
            radius: 50.w,
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.person, color: Colors.white, size: 50),
          ),
          SizedBox(height: 16.h),
          Text(
            'John Doe',
            style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          Text(
            'Senior Flutter Developer',
            style: TextStyle(fontSize: 16.sp, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32.h),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('اللغة / Language'),
            trailing: DropdownButton<String>(
              value: context.locale.languageCode,
              items: const [
                DropdownMenuItem(value: 'ar', child: Text('العربية')),
                DropdownMenuItem(value: 'en', child: Text('English')),
              ],
              onChanged: (val) {
                if (val != null) context.setLocale(Locale(val));
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: Text('logout'.tr(), style: const TextStyle(color: AppColors.error)),
            onTap: () {
              // Simulate logout
              context.go(AppRoutes.login);
            },
          ),
        ],
      ),
    );
  }
}
