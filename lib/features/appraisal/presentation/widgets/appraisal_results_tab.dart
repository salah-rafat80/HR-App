import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/appraisal_cubit.dart';
import '../bloc/appraisal_state.dart';
import 'package:hr_app_demo/core/widgets/app_loader.dart';


class AppraisalResultsTab extends StatelessWidget {
  const AppraisalResultsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppraisalCubit, AppraisalState>(
      builder: (context, state) {
        if (state is! AppraisalLoaded) return const AppLoader();
        final results = state.myResults;
        return SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: AppColors.primary.withValues(alpha: 0.1),
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    children: [
                      Text('overall_rating'.tr(), style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8.h),
                      Text('${results.overallRating} / 5.0', style: TextStyle(fontSize: 32.sp, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              ...results.categoryRatings.map((cat) => Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(cat.categoryName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
                        Text('${cat.score}', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    LinearProgressIndicator(value: cat.score / 5, backgroundColor: AppColors.background, color: AppColors.secondary, minHeight: 8.h, borderRadius: BorderRadius.circular(4)),
                    SizedBox(height: 4.h),
                    Text(cat.managerComment, style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
                  ],
                ),
              )),
              SizedBox(height: 16.h),
              Text('manager_summary'.tr(), style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 8.h),
              Text(results.managerSummary, style: TextStyle(fontSize: 14.sp)),
            ],
          ),
        );
      },
    );
  }
}
