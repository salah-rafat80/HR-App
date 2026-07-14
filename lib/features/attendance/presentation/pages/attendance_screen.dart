import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/attendance_cubit.dart';
import '../widgets/attendance_today_tab.dart';
import '../widgets/attendance_history_tab.dart';
import '../widgets/attendance_requests_tab.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<AttendanceCubit>()..loadAttendanceData(),
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text('attendance_title'.tr()),
            bottom: TabBar(
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              tabs: [
                Tab(text: 'today_tab'.tr()),
                Tab(text: 'history_tab'.tr()),
                Tab(text: 'requests_tab'.tr()),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              AttendanceTodayTab(),
              AttendanceHistoryTab(),
              AttendanceRequestsTab(),
            ],
          ),
        ),
      ),
    );
  }
}
