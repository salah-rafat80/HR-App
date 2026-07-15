import 'package:flutter/material.dart';
import 'package:hr_app_demo/core/theme/app_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../bloc/leave_cubit.dart';
import '../bloc/leave_state.dart';
import 'package:hr_app_demo/core/widgets/app_loader.dart';
import '../../../../core/widgets/app_card.dart';


class LeaveTeamCalendarTab extends StatelessWidget {
  const LeaveTeamCalendarTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LeaveCubit, LeaveState>(
      builder: (context, state) {
        if (state is! LeaveLoaded) return const AppLoader();
        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: state.teamCalendar.length,
          itemBuilder: (context, index) {
            final entry = state.teamCalendar[index];
            final df = DateFormat('dd MMM', context.locale.languageCode);
            return AppCard(
              margin: EdgeInsets.only(bottom: 8.h),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(AppIcons.profile)),
                title: Text(entry.colleagueName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
                subtitle: Text('${df.format(entry.startDate)} - ${df.format(entry.endDate)}', style: TextStyle(fontSize: 12.sp)),
              ),
            );
          },
        );
      },
    );
  }
}
