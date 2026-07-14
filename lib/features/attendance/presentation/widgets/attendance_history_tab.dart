import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/attendance_cubit.dart';
import '../bloc/attendance_state.dart';
import 'package:hr_app_demo/core/widgets/app_loader.dart';


class AttendanceHistoryTab extends StatelessWidget {
  const AttendanceHistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AttendanceCubit, AttendanceState>(
      builder: (context, state) {
        if (state is! AttendanceLoaded) return const AppLoader();
        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: state.history.length,
          itemBuilder: (context, index) {
            final record = state.history[index];
            final df = DateFormat('EEE, dd MMM yyyy', context.locale.languageCode);
            return Card(
              margin: EdgeInsets.only(bottom: 8.h),
              child: ListTile(
                title: Text(df.format(record.date), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
                subtitle: Text(record.locationLabel, style: TextStyle(fontSize: 12.sp)),
                trailing: Text(record.status.name.tr(), style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
            );
          },
        );
      },
    );
  }
}
