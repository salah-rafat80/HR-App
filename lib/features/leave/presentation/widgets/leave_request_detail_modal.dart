import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/leave_request.dart';
import '../../domain/entities/leave_enums.dart';
import '../bloc/leave_cubit.dart';
import '../bloc/leave_state.dart';

class LeaveRequestDetailModal extends StatelessWidget {
  final LeaveRequest request;
  const LeaveRequestDetailModal({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LeaveCubit, LeaveState>(
      builder: (context, state) {
        if (state is! LeaveLoaded) return const SizedBox.shrink();
        final currentReq = state.requests.firstWhere((r) => r.id == request.id, orElse: () => request);
        return Padding(
          padding: EdgeInsets.all(16.w).copyWith(top: 24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(currentReq.type.name.tr(), style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 16.h),
              ...currentReq.approvalSteps.map((s) => ListTile(
                leading: Icon(
                  s.status == LeaveStatus.approved ? Icons.check_circle : s.status == LeaveStatus.rejected ? Icons.cancel : Icons.pending,
                  color: s.status == LeaveStatus.approved ? AppColors.success : s.status == LeaveStatus.rejected ? AppColors.error : AppColors.warning,
                ),
                title: Text(s.stepName.tr(), style: TextStyle(fontSize: 14.sp)),
                subtitle: Text(s.status.name.tr(), style: TextStyle(fontSize: 12.sp)),
              )),
              SizedBox(height: 24.h),
              if (currentReq.overallStatus == LeaveStatus.pending)
                Container(
                  decoration: BoxDecoration(border: Border.all(color: AppColors.primary, style: BorderStyle.solid), borderRadius: BorderRadius.circular(8)),
                  child: TextButton.icon(
                    onPressed: () => context.read<LeaveCubit>().advanceApprovalStep(currentReq.id),
                    icon: const Icon(Icons.play_arrow),
                    label: Text('simulate_step'.tr()),
                  ),
                ),
              SizedBox(height: 24.h),
            ],
          ),
        );
      },
    );
  }
}
