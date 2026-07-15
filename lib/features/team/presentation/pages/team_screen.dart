import 'package:flutter/material.dart';
import 'package:hr_app_demo/core/widgets/app_custom_bar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/bloc/session_cubit.dart';
import '../../../../core/enums/role_enums.dart';
import '../../../../core/di/injection.dart';
import '../widgets/team_approvals_tab.dart';
import '../widgets/team_kpi_overview_tab.dart';
import '../widgets/recruitment_pipeline_tab.dart';

class TeamScreen extends StatelessWidget {
  const TeamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final role = getIt<SessionCubit>().state;
    final isManager = role == UserRole.manager;
    final tabCount = isManager ? 3 : 2;

    return DefaultTabController(
      length: tabCount,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppCustomBar(
          automaticallyImplyLeading: false,
          title: const Text('My Team'),
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            isScrollable: true,
            tabs: [
              const Tab(text: 'Approvals'),
              const Tab(text: 'KPI Overview'),
              if (isManager) const Tab(text: 'Recruitment'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const TeamApprovalsTab(),
            const TeamKpiOverviewTab(),
            if (isManager) const RecruitmentPipelineTab(),
          ],
        ),
      ),
    );
  }
}
