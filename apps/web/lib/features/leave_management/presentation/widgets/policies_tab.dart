import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hr_core/features/leave/domain/entities/leave_policy.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/leave_management_cubit.dart';
import 'leave_policy_form_dialog.dart';

class PoliciesTab extends StatelessWidget {
  final List<LeavePolicy> policies;
  final String? policiesError;
  final bool isSubmitting;

  const PoliciesTab({
    super.key,
    required this.policies,
    this.policiesError,
    required this.isSubmitting,
  });

  void _showPolicyFormDialog(
    BuildContext context, {
    LeavePolicy? existingPolicy,
  }) {
    final cubit = context.read<LeaveManagementCubit>();
    showDialog(
      context: context,
      builder: (ctx) =>
          LeavePolicyFormDialog(existingPolicy: existingPolicy, cubit: cubit),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (policiesError != null && policies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'failed_to_load_policies'.tr(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(policiesError!, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  context.read<LeaveManagementCubit>().refreshPolicies(),
              child: Text('retry'.tr()),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'leave_policies'.tr(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: Text('create_policy'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onPressed: () => _showPolicyFormDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (policies.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(child: Text('no_policies_found'.tr())),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 400,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                mainAxisExtent: 240,
              ),
              itemCount: policies.length,
              itemBuilder: (context, index) {
                final policy = policies[index];
                return Card(
                  elevation: 4,
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
                            Expanded(
                              child: Text(
                                policy.displayNameAr.isEmpty
                                    ? policy.type.name.tr()
                                    : policy.displayNameAr,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Switch(
                              value: policy.isActive,
                              onChanged: (val) {
                                context
                                    .read<LeaveManagementCubit>()
                                    .togglePolicy(policy.type);
                              },
                              activeColor: AppColors.primary,
                            ),
                          ],
                        ),
                        const Divider(),
                        const SizedBox(height: 6),
                        Text(
                          '${'annualEntitlement'.tr()}: ${policy.annualEntitlement} ${'days'.tr()}',
                        ),
                        const SizedBox(height: 4),
                        Text('${'leave_type'.tr()}: ${policy.type.name.tr()}'),
                        const SizedBox(height: 4),
                        Text(
                          '${'minimumNoticeDays'.tr()}: ${policy.minimumNoticeDays} ${'days'.tr()}',
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _Badge(
                              label: policy.isPaid
                                  ? 'isPaid'.tr()
                                  : 'unpaid'.tr(),
                              color: policy.isPaid
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            _Badge(
                              label: policy.requiresBalance
                                  ? 'requiresBalance'.tr()
                                  : 'no_balance_required'.tr(),
                              color: policy.requiresBalance
                                  ? Colors.blue
                                  : Colors.grey,
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () => _showPolicyFormDialog(
                                context,
                                existingPolicy: policy,
                              ),
                              tooltip: 'edit_policy'.tr(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
