import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/bloc/session_cubit.dart';
import '../../../../core/widgets/app_custom_bar.dart';
import '../widgets/profile_header_card.dart';
import '../widgets/profile_info_card.dart';
import '../widgets/profile_settings_card.dart';
import '../widgets/logout_dialog.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        return BlocBuilder<SessionCubit, SessionState>(
          builder: (context, sessionState) {
            final profile = sessionState.userProfile;
            final name = profile?.name.isNotEmpty == true
                ? profile!.name
                : 'employee'.tr();
            final title = profile?.title?.isNotEmpty == true
                ? profile!.title!
                : (profile?.role.isNotEmpty == true ? profile!.role.tr() : 'employee'.tr());
            final employeeCode = profile?.employeeCode ?? '---';
            final department = profile?.department ?? 'none'.tr();
            final email = profile?.email ?? '---';
            final roleName = profile?.role ?? 'employee';

            return Scaffold(
              appBar: AppCustomBar(
                automaticallyImplyLeading: false,
                title: Text('profile'.tr()),
              ),
              body: RefreshIndicator(
                onRefresh: () async {
                  await context.read<SessionCubit>().checkStoredSession();
                },
                child: ListView(
                  padding: EdgeInsets.all(16.w),
                  children: [
                    ProfileHeaderCard(
                      name: name,
                      title: title,
                      employeeCode: employeeCode,
                      department: department,
                    ),
                    SizedBox(height: 16.h),
                    ProfileInfoCard(
                      email: email,
                      employeeCode: employeeCode,
                      department: department,
                      roleName: roleName,
                    ),
                    SizedBox(height: 16.h),
                    ProfileSettingsCard(themeMode: themeMode),
                    SizedBox(height: 24.h),
                    ElevatedButton.icon(
                      onPressed: () => LogoutDialog.show(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        minimumSize: Size(double.infinity, 48.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      icon: const Icon(Icons.logout),
                      label: Text(
                        'logout'.tr(),
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
