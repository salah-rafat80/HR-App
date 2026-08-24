import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hr_core/features/leave/domain/entities/leave_enums.dart';
import 'package:hr_core/features/leave/domain/entities/leave_request.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../bloc/approvals_cubit.dart';

class ApprovalsDataTable extends StatelessWidget {
  final List<LeaveRequest> items;

  const ApprovalsDataTable({super.key, required this.items});

  void _showApproveDialog(BuildContext context, LeaveRequest req) {
    final commentController = TextEditingController();
    final cubit = context.read<ApprovalsCubit>();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('approve'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${req.employeeName ?? 'employee_default'.tr()} ${req.employeeCode != null ? '(${req.employeeCode})' : ''}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${'duration'.tr()}: ${DateFormat('yyyy-MM-dd').format(req.startDate)} - ${DateFormat('yyyy-MM-dd').format(req.endDate)} (${req.workingDays ?? 0} ${'days'.tr()})',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: commentController,
              decoration: InputDecoration(
                labelText: 'comment'.tr(),
                hintText: 'comment_optional'.tr(),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              cubit.approve(
                req.id,
                comment: commentController.text.trim().isEmpty
                    ? null
                    : commentController.text.trim(),
                onError: (err) => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(err), backgroundColor: Colors.red),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text('approve'.tr()),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, LeaveRequest req) {
    final commentController = TextEditingController();
    final cubit = context.read<ApprovalsCubit>();
    String? errorText;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('reject'.tr()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${req.employeeName ?? 'employee_default'.tr()} ${req.employeeCode != null ? '(${req.employeeCode})' : ''}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '${'duration'.tr()}: ${DateFormat('yyyy-MM-dd').format(req.startDate)} - ${DateFormat('yyyy-MM-dd').format(req.endDate)} (${req.workingDays ?? 0} ${'days'.tr()})',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                decoration: InputDecoration(
                  labelText: 'reason'.tr(),
                  hintText: 'reason_mandatory'.tr(),
                  errorText: errorText,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text('cancel'.tr()),
            ),
            ElevatedButton(
              onPressed: () {
                final reason = commentController.text.trim();
                if (reason.isEmpty) {
                  setDialogState(() {
                    errorText = 'rejection_reason_required'.tr();
                  });
                  return;
                }
                Navigator.pop(dialogCtx);
                cubit.reject(
                  req.id,
                  comment: reason,
                  onError: (err) => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(err), backgroundColor: Colors.red),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('reject'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final req = items[index];
        final cubit = context.read<ApprovalsCubit>();
        final isFlight = cubit.isInFlight(req.id);
        final isPending = req.overallStatus == LeaveStatus.pending;
        final startStr = DateFormat('yyyy-MM-dd').format(req.startDate);
        final endStr = DateFormat('yyyy-MM-dd').format(req.endDate);

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${req.employeeName ?? 'employee_default'.tr()} ${req.employeeCode != null ? '(${req.employeeCode})' : ''} - ${req.type.name.tr()}',
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
                  ),
                  if (isFlight)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else if (isPending)
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _showApproveDialog(context, req),
                          icon: const Icon(Iconsax.tick_circle, size: 18),
                          label: Text('approve'.tr()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => _showRejectDialog(context, req),
                          icon: const Icon(Iconsax.close_circle, size: 18),
                          label: Text('reject'.tr()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'approval_timeline'.tr(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
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
        );
      },
    );
  }
}
