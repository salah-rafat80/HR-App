import 'package:flutter/material.dart';
import 'package:hr_app_demo/core/theme/app_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:hr_core/features/leave/domain/entities/leave_request.dart';
import 'package:hr_core/features/leave/domain/entities/leave_enums.dart';
import '../bloc/leave_cubit.dart';
import '../bloc/leave_state.dart';

class LeaveRequestDetailModal extends StatelessWidget {
  final LeaveRequest request;
  const LeaveRequestDetailModal({super.key, required this.request});

  void _showCancelDialog(BuildContext context, String requestId) {
    final reasonController = TextEditingController();
    final cubit = context.read<LeaveCubit>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('cancel_leave_request'.tr()),
        content: TextField(
          controller: reasonController,
          decoration: InputDecoration(
            labelText: 'cancellation_reason'.tr(),
            hintText: 'cancellation_reason_mandatory'.tr(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('reason_required'.tr()),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context); // Close details modal
              cubit.cancelRequestWithReason(requestId, reason);
            },
            child: Text('submit'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Normalize now to midnight for date-only comparison
    final today = DateTime(now.year, now.month, now.day);

    return BlocBuilder<LeaveCubit, LeaveState>(
      builder: (context, state) {
        if (state is! LeaveLoaded) return const SizedBox.shrink();
        final currentReq = state.requests.firstWhere(
          (r) => r.id == request.id,
          orElse: () => request,
        );

        // Future request = starts after today
        final isFuture = currentReq.startDate.isAfter(today);
        final isPending = currentReq.overallStatus == LeaveStatus.pending;

        return Padding(
          padding: EdgeInsets.all(16.w).copyWith(top: 24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                currentReq.type.name.tr(),
                style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16.h),
              Text(
                '${'duration'.tr()}: ${DateFormat('yyyy-MM-dd').format(currentReq.startDate)} ${'to'.tr()} ${DateFormat('yyyy-MM-dd').format(currentReq.endDate)}',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              if (currentReq.workingDays != null) ...[
                SizedBox(height: 4.h),
                Text(
                  '${'working_days'.tr()}: ${currentReq.workingDays}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
              SizedBox(height: 16.h),
              Text(
                'approval_chain'.tr(),
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8.h),
              ...currentReq.approvalSteps.map((s) {
                final approverText = s.expectedApproverName != null
                    ? '\n${'expected_approver'.tr()}: ${s.expectedApproverName}'
                    : '';
                return ListTile(
                  leading: Icon(
                    s.status == LeaveStatus.approved
                        ? AppIcons.approve
                        : s.status == LeaveStatus.rejected
                        ? AppIcons.reject
                        : AppIcons.attendance,
                    color: s.status == LeaveStatus.approved
                        ? AppColors.success
                        : s.status == LeaveStatus.rejected
                        ? AppColors.error
                        : AppColors.warning,
                  ),
                  title: Text(
                    s.stepName.tr(),
                    style: TextStyle(fontSize: 14.sp),
                  ),
                  subtitle: Text(
                    '${s.status.name.tr()}$approverText',
                    style: TextStyle(fontSize: 12.sp),
                  ),
                );
              }),
              SizedBox(height: 24.h),
              if (isPending && isFuture)
                ElevatedButton(
                  onPressed: () => _showCancelDialog(context, currentReq.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('cancel_request'.tr()),
                ),
              SizedBox(height: 24.h),
            ],
          ),
        );
      },
    );
  }
}
