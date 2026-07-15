import 'package:flutter/material.dart';
import 'package:hr_app_demo/core/theme/app_icons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/home_entities.dart';
import '../../../../core/widgets/app_card.dart';

class HomeAnnouncementsSection extends StatelessWidget {
  final List<Announcement> announcements;

  const HomeAnnouncementsSection({super.key, required this.announcements});

  @override
  Widget build(BuildContext context) {
    if (announcements.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('announcements'.tr(), style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
              TextButton(onPressed: () {}, child: Text('view_all'.tr())),
            ],
          ),
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
        title: Text(announcement.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
        subtitle: Text(announcement.content, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.sp)),
        trailing: Text(df.format(announcement.date), style: TextStyle(fontSize: 10.sp, color: AppColors.textSecondary)),
      ),
    );
  }
}
