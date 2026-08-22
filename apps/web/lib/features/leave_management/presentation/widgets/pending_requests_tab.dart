import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hr_core/features/leave/domain/entities/leave_enums.dart';
import 'package:hr_core/features/leave/domain/entities/leave_request.dart';
import '../bloc/leave_management_cubit.dart';

class PendingRequestsTab extends StatelessWidget {
  final List<LeaveRequest> requests;
  final String? pendingRequestsError;
  final bool isSubmitting;

  const PendingRequestsTab({
    super.key,
    required this.requests,
    this.pendingRequestsError,
    required this.isSubmitting,
  });

  void _showDecisionDialog(
    BuildContext context,
    LeaveRequest request,
    bool isApprove,
  ) {
    final commentController = TextEditingController();
    final cubit = context.read<LeaveManagementCubit>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isApprove ? 'approve'.tr() : 'reject'.tr()),
        content: TextField(
          controller: commentController,
          decoration: InputDecoration(
            labelText: 'comment'.tr(),
            hintText: isApprove
                ? 'comment_optional'.tr()
                : 'reason_mandatory'.tr(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: isSubmitting
                ? null
                : () async {
                    final comment = commentController.text.trim();
                    if (!isApprove && comment.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('rejection_reason_required'.tr()),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    bool ok = false;
                    if (isApprove) {
                      ok = await cubit.approveRequest(
                        request.id,
                        comment.isEmpty ? null : comment,
                      );
                    } else {
                      ok = await cubit.rejectRequest(request.id, comment);
                    }
                    if (ok && ctx.mounted) {
                      Navigator.pop(ctx);
                    }
                  },
            child: isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('submit'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (pendingRequestsError != null && requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'failed_to_load_pending'.tr(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              pendingRequestsError!,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  context.read<LeaveManagementCubit>().refreshPendingRequests(),
              child: Text('retry'.tr()),
            ),
          ],
        ),
      );
    }

    if (requests.isEmpty) {
      return Center(child: Text('no_pending_requests'.tr()));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final req = requests[index];
        final startStr = DateFormat('yyyy-MM-dd').format(req.startDate);
        final endStr = DateFormat('yyyy-MM-dd').format(req.endDate);

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${req.employeeName ?? 'employee_default'.tr()} - ${req.type.name.tr()}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${'duration'.tr()}: $startStr to $endStr (${req.workingDays ?? 0} ${'days'.tr()})',
                        ),
                        const SizedBox(height: 4),
                        Text('${'reason'.tr()}: ${req.reason}'),
                      ],
                    ),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: isSubmitting
                              ? null
                              : () => _showDecisionDialog(context, req, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: Text('approve'.tr()),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: isSubmitting
                              ? null
                              : () => _showDecisionDialog(context, req, false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: Text('reject'.tr()),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 24),
                Text(
                  'approval_timeline'.tr(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: req.approvalSteps.map((step) {
                    final isCurrent = step.stepOrder == req.currentStepOrder;
                    final isApproved = step.status == LeaveStatus.approved;
                    final color = isApproved
                        ? Colors.green
                        : isCurrent
                        ? Colors.orange
                        : Colors.grey;
                    final approverName =
                        (step.expectedApprover?['name'] as String?) ??
                        step.expectedApproverId ??
                        'pending_approval_text'.tr();

                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: color,
                            width: isCurrent ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              step.stepName.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'employee_approver'.tr(
                                namedArgs: {'name': approverName},
                              ),
                              style: const TextStyle(fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'status_label'.tr(
                                namedArgs: {'status': step.status.name.tr()},
                              ),
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
