import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hr_app_demo/core/theme/app_colors.dart';
import 'package:hr_app_demo/core/theme/app_icons.dart';
import 'package:hr_app_demo/core/widgets/app_card.dart';
import 'package:hr_app_demo/core/widgets/app_loader.dart';
import 'package:hr_app_demo/core/widgets/empty_state_widget.dart';
import 'package:hr_core/features/attendance/domain/entities/attendance_enums.dart';
import '../bloc/attendance_cubit.dart';
import '../bloc/attendance_state.dart';

class AttendanceHistoryTab extends StatelessWidget {
  const AttendanceHistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AttendanceCubit, AttendanceState>(
      builder: (context, state) {
        if (state is! AttendanceLoaded) return const AppLoader();
        if (state.history.isEmpty) {
          return const EmptyStateWidget(
            icon: AppIcons.modules,
            message: 'no_data_found',
          );
        }

        final isArabic = context.locale.languageCode == 'ar';
        final timeFormat = DateFormat('hh:mm a', context.locale.languageCode);
        final dateFormat = DateFormat('EEEE, dd MMM yyyy', context.locale.languageCode);

        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: state.history.length,
          itemBuilder: (context, index) {
            final record = state.history[index];
            final dateStr = dateFormat.format(record.date);
            final clockInStr = record.clockInTime != null
                ? timeFormat.format(record.clockInTime!)
                : '--:--';
            final clockOutStr = record.clockOutTime != null
                ? timeFormat.format(record.clockOutTime!)
                : (record.clockInTime != null ? (isArabic ? 'جاري العمل' : 'Working') : '--:--');

            String durationStr = '--';
            if (record.clockInTime != null) {
              final endTime = record.clockOutTime ?? DateTime.now();
              final diff = endTime.difference(record.clockInTime!);
              final hours = diff.inHours;
              final minutes = diff.inMinutes.remainder(60);
              durationStr = isArabic ? '$hoursس $minutesد' : '${hours}h ${minutes}m';

            }

            final isPresent = record.status == AttendanceStatus.present || record.clockInTime != null;
            final isWorking = record.clockInTime != null && record.clockOutTime == null;

            final statusColor = isWorking
                ? Colors.blue
                : (isPresent ? AppColors.success : AppColors.error);

            final statusText = isWorking
                ? (isArabic ? 'جاري العمل' : 'Working')
                : (isPresent
                    ? (isArabic ? 'حاضر' : 'Present')
                    : record.status.name.tr());

            return AppCard(
              margin: EdgeInsets.only(bottom: 12.h),
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Date & Status Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_today_outlined, size: 16.sp, color: AppColors.primary),
                            SizedBox(width: 6.w),
                            Text(
                              dateStr,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14.sp,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                          ),

                          child: Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Divider(height: 20.h, thickness: 0.8),

                    // Body Grid: Clock In, Clock Out, Duration
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Clock In Column
                        _buildMetricColumn(
                          context: context,
                          label: isArabic ? 'الحضور' : 'Clock In',
                          value: clockInStr,
                          icon: Icons.login_rounded,
                          color: AppColors.success,
                        ),
                        // Clock Out Column
                        _buildMetricColumn(
                          context: context,
                          label: isArabic ? 'الانصراف' : 'Clock Out',
                          value: clockOutStr,
                          icon: Icons.logout_rounded,
                          color: isWorking ? Colors.orange : AppColors.error,
                        ),
                        // Duration Column
                        _buildMetricColumn(
                          context: context,
                          label: isArabic ? 'المدة' : 'Duration',
                          value: durationStr,
                          icon: Icons.timer_outlined,
                          color: AppColors.primary,
                        ),
                      ],
                    ),

                    // Footer: Branch Location Label
                    if (record.locationLabel.isNotEmpty && record.locationLabel != 'none') ...[
                      SizedBox(height: 12.h),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 14.sp, color: Colors.grey),
                          SizedBox(width: 4.w),
                          Text(
                            record.locationLabel,
                            style: TextStyle(fontSize: 12.sp, color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMetricColumn({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 14.sp, color: color),
            SizedBox(width: 4.w),
            Text(
              label,
              style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
            ),
          ],
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13.sp,
            color: color,
          ),
        ),
      ],
    );
  }
}

