import 'package:flutter/material.dart';
import 'package:hr_app_demo/core/widgets/app_custom_bar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/leave_cubit.dart';
import '../widgets/leave_overview_tab.dart';
import '../widgets/leave_requests_tab.dart';
import '../widgets/leave_team_calendar_tab.dart';

class LeaveScreen extends StatelessWidget {
  const LeaveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<LeaveCubit>()..loadData(),
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          
        appBar: AppCustomBar(
            automaticallyImplyLeading: false,
            title: Text('leave_overview'.tr()),
            bottom: TabBar(
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              tabs: [
                Tab(text: 'leave_overview'.tr()),
                Tab(text: 'my_requests'.tr()),
                Tab(text: 'team_calendar'.tr()),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              LeaveOverviewTab(),
              LeaveRequestsTab(),
              LeaveTeamCalendarTab(),
            ],
          ),
        ),
      ),
    );
  }
}
