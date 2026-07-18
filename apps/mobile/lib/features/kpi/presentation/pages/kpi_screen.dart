import 'package:flutter/material.dart';
import 'package:hr_app_demo/core/widgets/app_custom_bar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/kpi_cubit.dart';
import '../widgets/kpi_list_tab.dart';
import '../widgets/kpi_history_tab.dart';

class KpiScreen extends StatelessWidget {
  const KpiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<KpiCubit>()..loadData(),
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          
        appBar: AppCustomBar(
            title: Text('kpi_tracker'.tr()),
            bottom: TabBar(
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              tabs: [
                Tab(text: 'kpi_list'.tr()),
                Tab(text: 'kpi_history'.tr()),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              KpiListTab(),
              KpiHistoryTab(),
            ],
          ),
        ),
      ),
    );
  }
}
