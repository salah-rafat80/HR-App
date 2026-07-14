import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/training_entities.dart';
import '../bloc/training_cubit.dart';
import '../bloc/training_state.dart';
import 'package:hr_app_demo/core/widgets/app_loader.dart';


class TrainingCourseDetailModal extends StatelessWidget {
  final TrainingCourse course;
  const TrainingCourseDetailModal({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TrainingCubit, TrainingState>(
      builder: (context, state) {
        if (state is! TrainingLoaded) return const SizedBox.shrink();
        
        final currentCourse = state.availableCourses.firstWhere(
          (c) => c.id == course.id, 
          orElse: () => state.myEnrollments.firstWhere((c) => c.id == course.id, orElse: () => course)
        );

        return Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(currentCourse.title, style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 16.h),
              if (currentCourse.isMandatory)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Chip(label: Text('mandatory'.tr(), style: const TextStyle(color: Colors.white)), backgroundColor: AppColors.error),
                ),
              SizedBox(height: 16.h),
              Text('duration_hours'.tr(namedArgs: {'hours': currentCourse.durationHours.toString()}), style: TextStyle(fontSize: 14.sp)),
              SizedBox(height: 24.h),
              ElevatedButton(
                onPressed: currentCourse.isEnrolled || state.isEnrolling ? null : () {
                  context.read<TrainingCubit>().enroll(currentCourse.id);
                  Navigator.pop(context);
                },
                child: state.isEnrolling 
                    ? const AppLoader(size: 24)
                    : Text(currentCourse.isEnrolled ? 'enrolled'.tr() : 'enroll_now'.tr()),
              ),
            ],
          ),
        );
      },
    );
  }
}
