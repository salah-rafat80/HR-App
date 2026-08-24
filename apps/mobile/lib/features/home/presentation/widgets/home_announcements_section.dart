import 'package:flutter/material.dart';
import 'package:hr_app_demo/core/theme/app_icons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:hr_core/features/home/domain/entities/home_entities.dart';
import '../../../../core/widgets/app_card.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/bloc/session_cubit.dart';
import '../../../../core/di/injection.dart';
import '../../../communication/presentation/bloc/communication_cubit.dart';
import '../../../communication/presentation/widgets/new_announcement_modal.dart';

class HomeAnnouncementsSection extends StatelessWidget {
  final List<Announcement> announcements;

  const HomeAnnouncementsSection({super.key, required this.announcements});

  void _openAddModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (_) => BlocProvider.value(
        value: getIt<CommunicationCubit>(),
        child: const NewAnnouncementModal(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = context.watch<SessionCubit>().state;
    final role = sessionState.userProfile?.role ?? sessionState.role ?? '';
    final isAuthorizedAdmin = role == 'superAdmin' ||
        role == 'hrAdmin' ||
        role == 'super_admin' ||
        role == 'hr_admin';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'announcements'.tr(),
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (isAuthorizedAdmin) ...[
                    SizedBox(width: 8.w),
                    InkWell(
                      onTap: () => _openAddModal(context),
                      borderRadius: BorderRadius.circular(16.r),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_rounded,
                              size: 16.w,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              'إضافة إعلان',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              TextButton(
                onPressed: () => context.push(AppRoutes.communication),
                child: Text(
                  'view_all'.tr(),
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
            ],
          ),
          if (announcements.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: Text(
                'لا توجد إعلانات حالياً',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            ...announcements.map((a) => _AnnouncementCard(announcement: a)),
        ],
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final Announcement announcement;

  const _AnnouncementCard({required this.announcement});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd MMM', context.locale.languageCode);
    return AppCard(
      margin: EdgeInsets.only(bottom: 8.h),
      child: ListTile(
        leading: Icon(AppIcons.communication, color: AppColors.secondary, size: 32.w),
        title: Text(announcement.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp, color: AppColors.textPrimary)),
        subtitle: Text(announcement.content, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary)),
        trailing: Text(df.format(announcement.date), style: TextStyle(fontSize: 10.sp, color: AppColors.textSecondary)),
      ),
    );
  }
}
