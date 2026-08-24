import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/bloc/session_cubit.dart';
import '../../../../core/widgets/app_card.dart';

class ProfileSettingsCard extends StatelessWidget {
  final ThemeMode themeMode;

  const ProfileSettingsCard({
    super.key,
    required this.themeMode,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'app_settings'.tr(),
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(AppIcons.communication),
            title: Text('language'.tr()),
            trailing: DropdownButton<String>(
              value: context.locale.languageCode,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(value: 'ar', child: Text('العربية')),
                DropdownMenuItem(value: 'en', child: Text('English')),
              ],
              onChanged: (val) {
                if (val != null) context.setLocale(Locale(val));
              },
            ),
          ),
          ListTile(
            leading: const Icon(AppIcons.admin),
            title: Text('dark_mode'.tr()),
            trailing: Switch(
              value: themeMode == ThemeMode.dark,
              onChanged: (_) {
                context.read<ThemeCubit>().toggleTheme();
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.refresh_outlined),
            title: Text('refresh_profile'.tr()),
            onTap: () {
              context.read<SessionCubit>().checkStoredSession();
            },
          ),
        ],
      ),
    );
  }
}
