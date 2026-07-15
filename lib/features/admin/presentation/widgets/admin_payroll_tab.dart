import 'package:flutter/material.dart';
import 'package:hr_app_demo/core/theme/app_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/di/injection.dart';
import '../../domain/entities/payroll_run.dart';
import '../bloc/admin_payroll_cubit.dart';
import '../../../../core/widgets/app_card.dart';

class AdminPayrollTab extends StatelessWidget {
  const AdminPayrollTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AdminPayrollCubit>()..fetchRuns(),
      child: BlocBuilder<AdminPayrollCubit, AdminPayrollState>(
        builder: (context, state) {
          if (state is AdminPayrollLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is AdminPayrollLoaded) {
            return _buildContent(context, state.runs);
          } else if (state is AdminPayrollError) {
            return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<PayrollRun> runs) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16.w),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showCreateDialog(context),
              icon: const Icon(AppIcons.approve),
              label: const Text('Create Payroll Run'),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: runs.length,
            itemBuilder: (context, index) {
              final run = runs[index];
              return AppCard(
                margin: EdgeInsets.only(bottom: 12.h),
                child: ListTile(
                  title: Text(run.periodLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Employees: ${run.employeeCount} • Total: SAR ${run.totalAmount}'),
                  trailing: _buildStatusChip(run.status),
                  onTap: () => _showActionDialog(context, run),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(PayrollStatus status) {
    Color color;
    switch (status) {
      case PayrollStatus.paid:
        color = Colors.green;
        break;
      case PayrollStatus.approved:
        color = Colors.blue;
        break;
      case PayrollStatus.pendingApproval:
        color = Colors.orange;
        break;
      case PayrollStatus.processing:
        color = Colors.purple;
        break;
      case PayrollStatus.draft:
        color = Colors.grey;
        break;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12.r)),
      child: Text(status.name, style: TextStyle(color: color, fontSize: 12.sp)),
    );
  }

  void _showCreateDialog(BuildContext parentContext) {
    final ctrl = TextEditingController();
    showDialog(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('New Payroll Run'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Period (e.g. July 2026)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.isNotEmpty) {
                parentContext.read<AdminPayrollCubit>().createRun(ctrl.text);
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showActionDialog(BuildContext parentContext, PayrollRun run) {
    if (run.status == PayrollStatus.paid || run.status == PayrollStatus.approved) return;
    
    final isDraft = run.status == PayrollStatus.draft;
    final actionName = isDraft ? 'Process Run' : 'Approve Run';
    
    showDialog(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        title: Text(actionName),
        content: Text('Are you sure you want to ${actionName.toLowerCase()} for ${run.periodLabel}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (isDraft) {
                parentContext.read<AdminPayrollCubit>().processRun(run.id);
              } else {
                parentContext.read<AdminPayrollCubit>().approveRun(run.id);
              }
              Navigator.pop(dialogContext);
            },
            child: Text(actionName),
          ),
        ],
      ),
    );
  }
}
