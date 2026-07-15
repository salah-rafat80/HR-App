import 'package:flutter/material.dart';
import 'package:hr_app_demo/core/widgets/app_custom_bar.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../team/presentation/widgets/team_approvals_tab.dart';
import '../../../team/presentation/widgets/team_kpi_overview_tab.dart';
import '../widgets/admin_recruitment_tab.dart';
import '../widgets/admin_payroll_tab.dart';
import '../widgets/admin_system_config_tab.dart';
import '../widgets/admin_onboarding_tab.dart';
import '../widgets/admin_offboarding_tab.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 7,
      child: Scaffold(
        
        appBar: AppCustomBar(
          automaticallyImplyLeading: false,
          title: Text('admin_panel'.tr()),
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            isScrollable: true,
            tabs: [
              const Tab(text: 'Approvals'),
              const Tab(text: 'KPI Overview'),
              Tab(text: 'recruitment'.tr()),
              const Tab(text: 'Onboarding'),
              const Tab(text: 'Offboarding'),
              Tab(text: 'payroll_tab'.tr()),
              Tab(text: 'system_config'.tr()),
            ],
          ),
        ),
        body: TabBarView(
          children: const <Widget>[
            TeamApprovalsTab(),
            TeamKpiOverviewTab(),
            AdminRecruitmentTab(),
            AdminOnboardingTab(),
            AdminOffboardingTab(),
            AdminPayrollTab(),
            AdminSystemConfigTab(),
          ],
        ),
      ),
    );
  }
}
