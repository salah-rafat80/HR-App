import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../bloc/recruitment_cubit.dart';
import '../../../../core/widgets/app_card.dart';

class AdminOnboardingTab extends StatelessWidget {
  const AdminOnboardingTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<RecruitmentCubit>()..fetchData(),
      child: BlocBuilder<RecruitmentCubit, RecruitmentState>(
        builder: (context, state) {
          if (state is RecruitmentLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is RecruitmentLoaded) {
            return _buildContent(context, state);
          } else if (state is RecruitmentError) {
            return Center(
                child: Text(state.message,
                    style: const TextStyle(color: Colors.red)));
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, RecruitmentLoaded state) {
    if (state.onboardingRecords.isEmpty) {
      return Center(
        child: Text('No onboarding cases at the moment.',
            style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: state.onboardingRecords.length,
      itemBuilder: (context, index) {
        final record = state.onboardingRecords[index];
        return AppCard(
          margin: EdgeInsets.only(bottom: 12.h),
          child: ExpansionTile(
            title: Text(record.hireName,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Start Date: ${record.startDate}'),
                SizedBox(height: 8.h),
                LinearProgressIndicator(
                  value: record.completionPercent,
                  color: AppColors.primary,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${(record.completionPercent * 100).toStringAsFixed(0)}% Complete',
                  style: TextStyle(fontSize: 12.sp, color: AppColors.primary),
                ),
              ],
            ),
            children: record.tasks
                .map((t) => CheckboxListTile(
                      title: Text(t.title),
                      value: t.completed,
                      activeColor: AppColors.primary,
                      onChanged: (bool? value) {
                        context
                            .read<RecruitmentCubit>()
                            .toggleOnboardingTask(record.id, t.id);
                      },
                    ))
                .toList(),
          ),
        );
      },
    );
  }
}
