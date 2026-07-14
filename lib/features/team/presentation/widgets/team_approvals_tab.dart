import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/bloc/session_cubit.dart';
import '../../../../core/enums/role_enums.dart';
import '../../../../core/di/injection.dart';
import '../../../leave/domain/entities/leave_request.dart';
import '../bloc/team_approvals_cubit.dart';

class TeamApprovalsTab extends StatelessWidget {
  const TeamApprovalsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final role = getIt<SessionCubit>().state;
        final scope = role == UserRole.manager ? ApprovalScope.department : ApprovalScope.team;
        return getIt<TeamApprovalsCubit>()..fetchPendingApprovals(scope);
      },
      child: BlocBuilder<TeamApprovalsCubit, TeamApprovalsState>(
        builder: (context, state) {
          if (state is TeamApprovalsLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is TeamApprovalsLoaded) {
            return _buildList(context, state.requests);
          } else if (state is TeamApprovalsError) {
            return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildList(BuildContext context, List<LeaveRequest> requests) {
    if (requests.isEmpty) {
      return Center(
        child: Text('No pending approvals.', style: TextStyle(color: AppColors.textSecondary, fontSize: 16.sp)),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final req = requests[index];
        return Card(
          margin: EdgeInsets.only(bottom: 12.h),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(req.employeeName ?? 'Unknown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
                SizedBox(height: 4.h),
                Text('${req.type.name.toUpperCase()} Leave', style: TextStyle(color: AppColors.primary)),
                SizedBox(height: 8.h),
                Text('Reason: ${req.reason}'),
                SizedBox(height: 12.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => _handleReject(context, req.id),
                      child: const Text('Reject', style: TextStyle(color: Colors.red)),
                    ),
                    SizedBox(width: 8.w),
                    ElevatedButton(
                      onPressed: () => _handleApprove(context, req.id),
                      child: const Text('Approve'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleApprove(BuildContext context, String id) {
    final role = getIt<SessionCubit>().state;
    final scope = role == UserRole.manager ? ApprovalScope.department : ApprovalScope.team;
    context.read<TeamApprovalsCubit>().approveRequest(id, scope);
  }

  void _handleReject(BuildContext context, String id) {
    final role = getIt<SessionCubit>().state;
    final scope = role == UserRole.manager ? ApprovalScope.department : ApprovalScope.team;
    context.read<TeamApprovalsCubit>().rejectRequest(id, scope);
  }
}
