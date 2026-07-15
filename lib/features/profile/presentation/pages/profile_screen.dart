import 'package:flutter/material.dart';
import 'package:hr_app_demo/core/widgets/app_custom_bar.dart';
import 'package:hr_app_demo/core/theme/app_icons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/theme_cubit.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        return Scaffold(
          extendBodyBehindAppBar: true,
        appBar: AppCustomBar(automaticallyImplyLeading: false, title: Text('profile'.tr())),
          body: ListView(
            padding: EdgeInsets.all(16.w),
            children: [
              CircleAvatar(
                radius: 50.w,
                backgroundColor: AppColors.primary,
                child: const Icon(AppIcons.profile, color: Colors.white, size: 50),
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
                leading: const Icon(AppIcons.communication),
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
                leading: const Icon(AppIcons.admin),
                title: const Text('Dark Mode'),
                trailing: Switch(
                  value: themeMode == ThemeMode.dark,
                  onChanged: (val) {
                    context.read<ThemeCubit>().toggleTheme();
                  },
                ),
              ),
              const Divider(),
              ListTile(
                leading: Icon(AppIcons.back, color: AppColors.error),
                title: Text('logout'.tr(), style: TextStyle(color: AppColors.error)),
                onTap: () {
                  context.go(AppRoutes.login);
                },
              ),
            ],
          ),
        );
      }
    );
  }
}
