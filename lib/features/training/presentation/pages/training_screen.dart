import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/training_cubit.dart';
import '../bloc/training_state.dart';
import '../widgets/training_browse_tab.dart';
import '../widgets/training_enrollments_tab.dart';
import '../widgets/training_certifications_tab.dart';

class TrainingScreen extends StatelessWidget {
  const TrainingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<TrainingCubit>()..loadData(),
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: Text('training_title'.tr()),
            bottom: TabBar(
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              tabs: [
                Tab(text: 'browse_courses'.tr()),
                Tab(text: 'my_enrollments'.tr()),
                Tab(text: 'certifications'.tr()),
              ],
            ),
          ),
          body: Column(
            children: [
              _buildMandatoryAlert(),
              const Expanded(
                child: TabBarView(
                  children: [
                    TrainingBrowseTab(),
                    TrainingEnrollmentsTab(),
                    TrainingCertificationsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMandatoryAlert() {
    return BlocBuilder<TrainingCubit, TrainingState>(
      builder: (context, state) {
        if (state is TrainingLoaded && state.pendingMandatory.isNotEmpty) {
          return Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.w),
            color: AppColors.warning.withValues(alpha: 0.1),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'mandatory_training_alert'.tr(namedArgs: {'count': state.pendingMandatory.length.toString()}),
                    style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold, fontSize: 12.sp),
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
