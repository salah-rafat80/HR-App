import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/communication_cubit.dart';
import '../bloc/communication_state.dart';
import 'package:hr_app_demo/core/widgets/app_loader.dart';


class CommAnnouncementsTab extends StatelessWidget {
  const CommAnnouncementsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CommunicationCubit, CommunicationState>(
      builder: (context, state) {
        if (state is! CommunicationLoaded) return const AppLoader();
        if (state.announcements.isEmpty) return const Center(child: Text('No announcements'));

        final df = DateFormat('dd MMM yyyy', context.locale.languageCode);

        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: state.announcements.length,
          itemBuilder: (context, index) {
            final a = state.announcements[index];
            return Card(
              margin: EdgeInsets.only(bottom: 12.h),
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: a.department != null ? AppColors.secondary.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            a.department ?? 'company_wide'.tr(),
                            style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold, color: a.department != null ? AppColors.secondary : AppColors.primary),
                          ),
                        ),
                        Text(df.format(a.date), style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary)),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Text(a.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
                    SizedBox(height: 8.h),
                    Text(a.body, style: TextStyle(fontSize: 14.sp)),
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
