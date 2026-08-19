import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hr_core/features/leave/domain/entities/leave_policy.dart';
import 'package:hr_core/features/leave/domain/entities/leave_balance.dart';
import 'package:hr_core/features/leave/domain/entities/leave_request.dart';
import 'package:hr_core/core/enums/role_enums.dart';
import '../../../../core/bloc/session_cubit.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/leave_management_cubit.dart';
import 'package:hr_core/features/leave/domain/repositories/leave_repository.dart';

class LeaveManagementScreen extends StatefulWidget {
  const LeaveManagementScreen({super.key});

  @override
  State<LeaveManagementScreen> createState() => _LeaveManagementScreenState();
}

class _LeaveManagementScreenState extends State<LeaveManagementScreen> {
  final _searchController = TextEditingController();
  String? _selectedDept;
  int? _selectedYear = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionCubit>().state;
    final userRole = session.role ?? UserRole.employee;

    // Strict role protection at view level
    final isAllowed = userRole == UserRole.hr ||
        userRole == UserRole.hrAdmin ||
        userRole == UserRole.superAdmin;

    if (!isAllowed) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'access_denied'.tr(),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('only_hr_allowed'.tr()),
            ],
          ),
        ),
      );
    }

    return BlocProvider(
      create: (context) => LeaveManagementCubit(getIt<LeaveRepository>())
        ..loadDashboard(year: _selectedYear),
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text('leave_management_dashboard'.tr(),
                style: const TextStyle(fontWeight: FontWeight.bold)),
            bottom: TabBar(
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              tabs: [
                Tab(text: 'leave_policies'.tr()),
                Tab(text: 'balances_and_adjustments'.tr()),
                Tab(text: 'pending_requests'.tr()),
              ],
            ),
          ),
          body: BlocBuilder<LeaveManagementCubit, LeaveManagementState>(
            builder: (context, state) {
              if (state is LeaveManagementInitial || state is LeaveManagementLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is LeaveManagementError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(state.message),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context
                            .read<LeaveManagementCubit>()
                            .loadDashboard(year: _selectedYear),
                        child: Text('retry'.tr()),
                      )
                    ],
                  ),
                );
              }

              if (state is LeaveManagementLoaded) {
                return TabBarView(
                  children: [
                    _PoliciesTab(policies: state.policies),
                    _BalancesTab(
                      balances: state.balances,
                      selectedYear: _selectedYear,
                      searchController: _searchController,
                      selectedDept: _selectedDept,
                      onFilterChanged: (year, dept, search) {
                        setState(() {
                          _selectedYear = year;
                          _selectedDept = dept;
                        });
                        context.read<LeaveManagementCubit>().loadDashboard(
                              year: year,
                              department: dept,
                              employeeId: search.isEmpty ? null : search,
                            );
                      },
                      config: state.config,
                      userRole: userRole,
                    ),
                    _PendingRequestsTab(requests: state.pendingRequests),
                  ],
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}

// Policies Tab
class _PoliciesTab extends StatelessWidget {
  final List<LeavePolicy> policies;

  const _PoliciesTab({required this.policies});

  @override
  Widget build(BuildContext context) {
    if (policies.isEmpty) {
      return Center(child: Text('no_policies_found'.tr()));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('leave_policies_subtitle'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 400,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              mainAxisExtent: 220,
            ),
            itemCount: policies.length,
            itemBuilder: (context, index) {
              final policy = policies[index];
              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            policy.displayNameAr,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
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
                      const SizedBox(height: 8),
                      Text('${'entitlement'.tr()}: ${policy.annualEntitlement} ${'days'.tr()}'),
                      const SizedBox(height: 4),
                      Text('${'type'.tr()}: ${policy.type.name}'),
                      const SizedBox(height: 4),
                      Text('${'minimum_notice'.tr()}: ${policy.minimumNoticeDays} ${'days'.tr()}'),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _Badge(
                            label: policy.isPaid ? 'paid'.tr() : 'unpaid'.tr(),
                            color: policy.isPaid ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          _Badge(
                            label: policy.requiresBalance
                                ? 'requires_balance'.tr()
                                : 'no_balance_required'.tr(),
                            color: policy.requiresBalance
                                ? Colors.blue
                                : Colors.grey,
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

// Balances Tab
class _BalancesTab extends StatelessWidget {
  final List<LeaveBalance> balances;
  final int? selectedYear;
  final TextEditingController searchController;
  final String? selectedDept;
  final Function(int?, String?, String) onFilterChanged;
  final Map<String, dynamic> config;
  final UserRole userRole;

  const _BalancesTab({
    required this.balances,
    required this.selectedYear,
    required this.searchController,
    required this.selectedDept,
    required this.onFilterChanged,
    required this.config,
    required this.userRole,
  });

  void _showAdjustDialog(BuildContext context, LeaveBalance balance) {
    final countController = TextEditingController();
    final reasonController = TextEditingController();
    final cubit = context.read<LeaveManagementCubit>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('adjust_leave_balance'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: countController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'adjustment_amount'.tr(),
                hintText: 'e.g. 5.5 or -3.0',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'reason'.tr(),
                hintText: 'adjustment_reason_mandatory'.tr(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(countController.text.trim());
              final reason = reasonController.text.trim();
              if (amount == null || reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('invalid_input_or_reason_missing'.tr()),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.pop(ctx);
              cubit.adjustBalance(
                balanceId: balance.toJson()['id'] as String? ?? '',
                adjustmentDays: amount,
                reason: reason,
              );
            },
            child: Text('save'.tr()),
          ),
        ],
      ),
    );
  }

  void _showConfigDialog(BuildContext context) {
    final hrApproverController = TextEditingController(
      text: config['finalHrApproverId'] as String? ?? '',
    );
    final cubit = context.read<LeaveManagementCubit>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('final_hr_approver_config'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('final_hr_approver_desc'.tr(),
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: hrApproverController,
              decoration: InputDecoration(
                labelText: 'approver_user_id'.tr(),
                hintText: 'uuid_of_hr_user'.tr(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              final approverId = hrApproverController.text.trim();
              Navigator.pop(ctx);
              cubit.updateCompanyApprovalConfig(
                approverId.isEmpty ? null : approverId,
              );
            },
            child: Text('save'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hrApprover = config['finalHrApprover'] != null
        ? config['finalHrApprover']['name'] as String
        : 'not_configured'.tr();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'balances_subtitle'.tr(),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Text(
                    '${'final_hr_approver'.tr()}: $hrApprover',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (userRole == UserRole.superAdmin) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.settings, color: AppColors.primary),
                      onPressed: () => _showConfigDialog(context),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    labelText: 'search_employee_id'.tr(),
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                  ),
                  onSubmitted: (val) {
                    onFilterChanged(selectedYear, selectedDept, val);
                  },
                ),
              ),
              const SizedBox(width: 16),
              DropdownButton<int>(
                value: selectedYear,
                items: [2026, 2027, 2028]
                    .map((y) => DropdownMenuItem(value: y, child: Text(y.toString())))
                    .toList(),
                onChanged: (val) {
                  onFilterChanged(val, selectedDept, searchController.text.trim());
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: balances.isEmpty
                ? Center(child: Text('no_balances_found'.tr()))
                : ListView.builder(
                    itemCount: balances.length,
                    itemBuilder: (context, index) {
                      final balance = balances[index];
                      final balanceJson = balance.toJson();
                      final userName = balanceJson['user']?['name'] as String? ?? 'Employee';
                      final code = balanceJson['user']?['employeeCode'] as String? ?? '';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text('$userName ($code)'),
                          subtitle: Text(
                            '${'type'.tr()}: ${balance.type.name.tr()} | '
                            '${'entitled'.tr()}: ${balance.entitledDays ?? 0} | '
                            '${'adjusted'.tr()}: ${balance.adjustmentDays ?? 0} | '
                            '${'reserved'.tr()}: ${balance.reservedDays ?? 0} | '
                            '${'used'.tr()}: ${balance.usedDays ?? 0}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${balance.availableDays} ${'days_available'.tr()}',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: () => _showAdjustDialog(context, balance),
                                child: Text('adjust'.tr()),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// Pending Requests Tab
class _PendingRequestsTab extends StatelessWidget {
  final List<LeaveRequest> requests;

  const _PendingRequestsTab({required this.requests});

  void _showDecisionDialog(
      BuildContext context, LeaveRequest request, bool isApprove) {
    final commentController = TextEditingController();
    final cubit = context.read<LeaveManagementCubit>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isApprove ? 'approve_leave_request'.tr() : 'reject_leave_request'.tr()),
        content: TextField(
          controller: commentController,
          decoration: InputDecoration(
            labelText: 'comment'.tr(),
            hintText: isApprove ? 'optional_comment'.tr() : 'rejection_reason_mandatory'.tr(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              final comment = commentController.text.trim();
              if (!isApprove && comment.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('rejection_reason_mandatory'.tr()),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.pop(ctx);
              if (isApprove) {
                cubit.approveRequest(request.id, comment.isEmpty ? null : comment);
              } else {
                cubit.rejectRequest(request.id, comment);
              }
            },
            child: Text('submit'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${req.employeeName ?? 'Employee'} - ${req.type.name.tr()}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('${'duration'.tr()}: $startStr to $endStr (${req.workingDays ?? 0} ${'days'.tr()})'),
                    const SizedBox(height: 4),
                    Text('${'reason'.tr()}: ${req.reason}'),
                  ],
                ),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () => _showDecisionDialog(context, req, true),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green, foregroundColor: Colors.white),
                      child: Text('approve'.tr()),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _showDecisionDialog(context, req, false),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red, foregroundColor: Colors.white),
                      child: Text('reject'.tr()),
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
}

// Helpers
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
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
