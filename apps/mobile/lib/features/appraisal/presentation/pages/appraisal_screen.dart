import 'package:flutter/material.dart';
import 'package:hr_app_demo/core/widgets/app_custom_bar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/appraisal_cubit.dart';
import '../widgets/appraisal_overview_tab.dart';
import '../widgets/appraisal_peer_feedback_tab.dart';
import '../widgets/appraisal_results_tab.dart';
import '../widgets/appraisal_dev_plan_tab.dart';
import '../widgets/appraisal_career_path_tab.dart';

class AppraisalScreen extends StatelessWidget {
  const AppraisalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<AppraisalCubit>()..loadData(),
      child: DefaultTabController(
        length: 5,
        child: Scaffold(
          
        appBar: AppCustomBar(
            title: Text('appraisal_title'.tr()),
            bottom: TabBar(
              isScrollable: true,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              tabs: [
                Tab(text: 'cycle_overview'.tr()),
                Tab(text: 'peer_feedback'.tr()),
                Tab(text: 'my_results'.tr()),
                Tab(text: 'dev_plan'.tr()),
                Tab(text: 'career_path'.tr()),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              AppraisalOverviewTab(),
              AppraisalPeerFeedbackTab(),
              AppraisalResultsTab(),
              AppraisalDevPlanTab(),
              AppraisalCareerPathTab(),
            ],
          ),
        ),
      ),
    );
  }
}
