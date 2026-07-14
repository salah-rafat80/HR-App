import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/appraisal_cubit.dart';
import '../bloc/appraisal_state.dart';
import 'package:hr_app_demo/core/widgets/app_loader.dart';


class AppraisalDevPlanTab extends StatelessWidget {
  const AppraisalDevPlanTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppraisalCubit, AppraisalState>(
      builder: (context, state) {
        if (state is! AppraisalLoaded) return const AppLoader();
        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: state.devPlan.length,
          itemBuilder: (context, index) {
            final goal = state.devPlan[index];
            return Card(
              margin: EdgeInsets.only(bottom: 12.h),
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
                    SizedBox(height: 12.h),
                    LinearProgressIndicator(value: goal.progressPercent, backgroundColor: AppColors.background, color: AppColors.primary, minHeight: 8.h, borderRadius: BorderRadius.circular(4)),
                    SizedBox(height: 8.h),
                    Text('${(goal.progressPercent * 100).toInt()}%', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
