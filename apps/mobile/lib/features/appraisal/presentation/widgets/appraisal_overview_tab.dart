import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/appraisal_cubit.dart';
import '../bloc/appraisal_state.dart';
import 'self_appraisal_modal.dart';
import 'package:hr_app_demo/core/widgets/app_loader.dart';
import '../../../../core/widgets/app_card.dart';


class AppraisalOverviewTab extends StatelessWidget {
  const AppraisalOverviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppraisalCubit, AppraisalState>(
      builder: (context, state) {
        if (state is! AppraisalLoaded) return const AppLoader();
        final df = DateFormat('dd MMM yyyy', context.locale.languageCode);
        return Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppCard(
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    children: [
                      Text(state.cycle.cycleLabel, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8.h),
                      Chip(
                        label: Text(state.cycle.status.name.tr(), style: const TextStyle(color: Colors.white)),
                        backgroundColor: AppColors.primary,
                      ),
                      SizedBox(height: 16.h),
                      Text('${'due_in'.tr()}: ${df.format(state.cycle.dueDate)}', style: TextStyle(fontSize: 14.sp)),
                      SizedBox(height: 24.h),
                      ElevatedButton(
                        onPressed: state.cycle.selfAppraisalSubmitted 
                          ? null 
                          : () => showModalBottomSheet(
                              context: context, 
                              isScrollControlled: true, 
                              builder: (_) => BlocProvider.value(value: context.read<AppraisalCubit>(), child: const SelfAppraisalModal())
                            ),
                        child: Text(state.cycle.selfAppraisalSubmitted ? 'view_submission'.tr() : 'start_self_appraisal'.tr()),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
