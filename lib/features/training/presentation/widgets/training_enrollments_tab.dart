import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/training_cubit.dart';
import '../bloc/training_state.dart';
import 'package:hr_app_demo/core/widgets/app_loader.dart';


class TrainingEnrollmentsTab extends StatelessWidget {
  const TrainingEnrollmentsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TrainingCubit, TrainingState>(
      builder: (context, state) {
        if (state is! TrainingLoaded) return const AppLoader();
        if (state.myEnrollments.isEmpty) return const Center(child: Text('No enrollments yet'));

        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: state.myEnrollments.length,
          itemBuilder: (context, index) {
            final course = state.myEnrollments[index];
            return Card(
              margin: EdgeInsets.only(bottom: 12.h),
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(course.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
                    SizedBox(height: 12.h),
                    LinearProgressIndicator(value: course.progressPercent, backgroundColor: AppColors.background, color: AppColors.primary, minHeight: 8.h, borderRadius: BorderRadius.circular(4)),
                    SizedBox(height: 8.h),
                    Text('${(course.progressPercent * 100).toInt()}%', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: AppColors.primary)),
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
