import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:hr_core/features/training/domain/entities/training_entities.dart';
import '../bloc/training_cubit.dart';
import '../bloc/training_state.dart';
import 'training_course_detail_modal.dart';
import 'package:hr_app_demo/core/widgets/app_loader.dart';
import '../../../../core/widgets/app_card.dart';


class TrainingBrowseTab extends StatelessWidget {
  const TrainingBrowseTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TrainingCubit, TrainingState>(
      builder: (context, state) {
        if (state is! TrainingLoaded) return const AppLoader();
        if (state.availableCourses.isEmpty) return const Center(child: Text('No courses available'));

        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: state.availableCourses.length,
          itemBuilder: (context, index) {
            final course = state.availableCourses[index];
            return AppCard(
              margin: EdgeInsets.only(bottom: 12.h),
              child: ListTile(
                onTap: () => _showCourseDetail(context, course),
                title: Row(
                  children: [
                    Expanded(child: Text(course.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp))),
                    if (course.isMandatory)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(4)),
                        child: Text('mandatory'.tr(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                subtitle: Padding(
                  padding: EdgeInsets.only(top: 8.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _getCategoryChip(course.category),
                      Text('duration_hours'.tr(namedArgs: {'hours': course.durationHours.toString()}), style: TextStyle(fontSize: 12.sp)),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showCourseDetail(BuildContext context, TrainingCourse course) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: context.read<TrainingCubit>(),
        child: TrainingCourseDetailModal(course: course),
      ),
    );
  }

  Widget _getCategoryChip(TrainingCategory category) {
    String label;
    Color color;
    switch (category) {
      case TrainingCategory.technical: label = 'category_technical'.tr(); color = AppColors.primary; break;
      case TrainingCategory.softSkills: label = 'category_soft_skills'.tr(); color = AppColors.success; break;
      case TrainingCategory.compliance: label = 'category_compliance'.tr(); color = AppColors.warning; break;
      case TrainingCategory.leadership: label = 'category_leadership'.tr(); color = AppColors.secondary; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color)),
      child: Text(label, style: TextStyle(color: color, fontSize: 10.sp, fontWeight: FontWeight.bold)),
    );
  }
}
