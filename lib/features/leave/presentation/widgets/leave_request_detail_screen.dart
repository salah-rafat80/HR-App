import 'package:flutter/material.dart';
import 'package:hr_app_demo/core/widgets/app_custom_bar.dart';
import 'package:hr_app_demo/core/theme/app_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/leave_request.dart';
import '../../domain/entities/leave_enums.dart';
import '../bloc/leave_cubit.dart';
import '../bloc/leave_state.dart';

class LeaveRequestDetailScreen extends StatelessWidget {
  final LeaveRequest request;
  const LeaveRequestDetailScreen({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LeaveCubit, LeaveState>(
      builder: (context, state) {
        if (state is! LeaveLoaded) return const SizedBox.shrink();
        final currentReq = state.requests.firstWhere((r) => r.id == request.id, orElse: () => request);
        return Scaffold(
          
        appBar: AppCustomBar(title: Text(currentReq.type.name.tr())),
          body: Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Hero(
                  tag: 'leave_${currentReq.id}',
                  child: Material(
                    color: Colors.transparent,
                    child: Text(currentReq.type.name.tr(), style: AppTextStyles.h2),
                  ),
                ),
                AppSpacing.verticalMd,
                ...currentReq.approvalSteps.map((s) => ListTile(
                  leading: Icon(
                    s.status == LeaveStatus.approved ? AppIcons.approve : s.status == LeaveStatus.rejected ? AppIcons.reject : AppIcons.attendance,
                    color: s.status == LeaveStatus.approved ? AppColors.success : s.status == LeaveStatus.rejected ? AppColors.error : AppColors.warning,
                  ),
                  title: Text(s.stepName.tr(), style: AppTextStyles.bodyMedium),
                  subtitle: Text(s.status.name.tr(), style: AppTextStyles.bodySmall),
                )),
                AppSpacing.verticalLg,
                if (currentReq.overallStatus == LeaveStatus.pending)
                  Container(
                    decoration: BoxDecoration(border: Border.all(color: AppColors.primary, style: BorderStyle.solid), borderRadius: BorderRadius.circular(8)),
                    child: TextButton.icon(
                      onPressed: () => context.read<LeaveCubit>().advanceApprovalStep(currentReq.id),
                      icon: const Icon(AppIcons.approve),
                      label: Text('simulate_step'.tr()),
                    ),
                  ),
                AppSpacing.verticalLg,
              ],
            ),
          ),
        );
      },
    );
  }
}
