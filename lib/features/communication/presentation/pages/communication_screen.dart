import 'package:flutter/material.dart';
import 'package:hr_app_demo/core/widgets/app_custom_bar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/communication_cubit.dart';
import '../widgets/comm_announcements_tab.dart';
import '../widgets/comm_hr_chat_tab.dart';
import '../widgets/comm_polls_tab.dart';
import '../widgets/comm_handbook_tab.dart';
import '../widgets/comm_it_requests_tab.dart';

class CommunicationScreen extends StatelessWidget {
  const CommunicationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<CommunicationCubit>()..loadData(),
      child: DefaultTabController(
        length: 5,
        child: Scaffold(
          
        appBar: AppCustomBar(
            title: Text('communication_hub'.tr()),
            bottom: TabBar(
              isScrollable: true,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              tabs: [
                Tab(text: 'announcements'.tr()),
                Tab(text: 'hr_chat'.tr()),
                Tab(text: 'polls_surveys'.tr()),
                Tab(text: 'handbook'.tr()),
                Tab(text: 'it_requests'.tr()),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              CommAnnouncementsTab(),
              CommHrChatTab(),
              CommPollsTab(),
              CommHandbookTab(),
              CommItRequestsTab(),
            ],
          ),
        ),
      ),
    );
  }
}
