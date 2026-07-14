import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/appraisal_entities.dart';
import '../bloc/appraisal_cubit.dart';
import '../bloc/appraisal_state.dart';
import 'package:hr_app_demo/core/widgets/app_loader.dart';


class AppraisalCareerPathTab extends StatelessWidget {
  const AppraisalCareerPathTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppraisalCubit, AppraisalState>(
      builder: (context, state) {
        if (state is! AppraisalLoaded) return const AppLoader();
        return ListView.builder(
          padding: EdgeInsets.all(24.w),
          itemCount: state.careerPath.length,
          itemBuilder: (context, index) {
            final step = state.careerPath[index];
            final isCurrent = step.status == CareerStepStatus.current;
            final isCompleted = step.status == CareerStepStatus.completed;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    CircleAvatar(
                      radius: 12.w,
                      backgroundColor: isCompleted ? AppColors.success : (isCurrent ? AppColors.primary : AppColors.background),
                      child: isCompleted ? Icon(Icons.check, size: 16.w, color: Colors.white) : null,
                    ),
                    if (index < state.careerPath.length - 1)
                      Container(width: 2, height: 40.h, color: isCompleted ? AppColors.success : AppColors.background),
                  ],
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(step.roleTitle, style: TextStyle(fontSize: 16.sp, fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal, color: isCurrent ? AppColors.primary : AppColors.textPrimary)),
                      if (isCurrent) Text('current_step'.tr(), style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary)),
                      SizedBox(height: 24.h),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
