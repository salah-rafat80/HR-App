import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';

class HomeGreetingHeader extends StatelessWidget {
  final String name;
  final DateTime date;
  final int pendingTrainings;

  const HomeGreetingHeader({super.key, required this.name, required this.date, this.pendingTrainings = 0});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, d MMMM y', context.locale.languageCode);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${'good_morning'.tr()}, $name',
                  style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                SizedBox(height: 4.h),
                Text(
                  dateFormat.format(date),
                  style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _buildNotificationBell(context),
              SizedBox(width: 16.w),
              CircleAvatar(
                radius: 24.w,
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.person, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationBell(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications),
          onPressed: () => _showNotifications(context),
        ),
        if (pendingTrainings > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                '$pendingTrainings',
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Notifications', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
                SizedBox(height: 16.h),
                if (pendingTrainings > 0)
                  ListTile(
                    leading: const Icon(Icons.warning, color: AppColors.warning),
                    title: Text('home_mandatory_training_notif'.tr(namedArgs: {'count': '$pendingTrainings'})),
                  )
                else
                  const ListTile(title: Text('No new notifications')),
                SizedBox(height: 16.h),
              ],
            ),
          ),
        );
      },
    );
  }
}
