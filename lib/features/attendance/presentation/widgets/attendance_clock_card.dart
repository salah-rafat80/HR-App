import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/attendance_cubit.dart';
import '../bloc/attendance_state.dart';
import 'package:hr_app_demo/core/widgets/app_loader.dart';


class AttendanceClockCard extends StatelessWidget {
  const AttendanceClockCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AttendanceCubit, AttendanceState>(
      builder: (context, state) {
        if (state is! AttendanceLoaded) return const AppLoader();
        final isClockedIn = state.todayStatus.clockInTime != null && state.todayStatus.clockOutTime == null;
        return Card(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_on, color: AppColors.success),
                    SizedBox(width: 8.w),
                    Text('inside_geofence'.tr(), style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 24.h),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isClockedIn ? AppColors.error : AppColors.primary,
                    shape: const CircleBorder(),
                    padding: EdgeInsets.all(40.w),
                  ),
                  onPressed: () {
                    isClockedIn ? context.read<AttendanceCubit>().clockOut() : context.read<AttendanceCubit>().clockIn('Main Office');
                  },
                  child: Text(isClockedIn ? 'clock_out'.tr() : 'clock_in'.tr(), style: TextStyle(fontSize: 18.sp)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
