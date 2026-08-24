import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hr_core/features/leave/domain/entities/leave_enums.dart';
import 'package:hr_core/features/leave/domain/entities/leave_balance.dart';
import 'package:hr_core/core/enums/role_enums.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/leave_management_cubit.dart';

class BalancesTab extends StatelessWidget {
  final List<LeaveBalance> balances;
  final String? balancesError;
  final int? selectedYear;
  final TextEditingController searchController;
  final String? selectedDept;
  final Function(int targetPage, int? year, String? dept, String search)
  onFilterChanged;
  final Map<String, dynamic> config;
  final List<Map<String, dynamic>> employees;
  final UserRole userRole;
  final int currentPage;
  final int totalPages;
  final int totalBalances;
  final bool isSubmitting;

  const BalancesTab({
    super.key,
    required this.balances,
    this.balancesError,
    required this.selectedYear,
    required this.searchController,
    required this.selectedDept,
    required this.onFilterChanged,
    required this.config,
    required this.employees,
    required this.userRole,
    required this.currentPage,
    required this.totalPages,
    required this.totalBalances,
    required this.isSubmitting,
  });

  void _showAdjustDialog(BuildContext context, LeaveBalance balance) {
    final countController = TextEditingController();
    final reasonController = TextEditingController();
    final cubit = context.read<LeaveManagementCubit>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('adjust_balance'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: countController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'adjustment_amount_prompt'.tr(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(labelText: 'reason'.tr()),
            ),
          ],
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
                    final amount = double.tryParse(countController.text.trim());
                    final reason = reasonController.text.trim();
                    if (amount == null || reason.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('rejection_reason_required'.tr()),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    final ok = await cubit.adjustBalance(
                      balanceId: balance.id ?? '',
                      adjustmentDays: amount,
                      reason: reason,
                    );
                    if (ok && ctx.mounted) {
                      Navigator.pop(ctx);
                    }
                  },
            child: Text('save'.tr()),
          ),
        ],
      ),
    );
  }

  void _showSearchableEmployeePicker(
    BuildContext context,
    Function(Map<String, dynamic>) onSelected,
  ) {
    final searchCtrl = TextEditingController();
    List<Map<String, dynamic>> filtered = List.from(employees);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('select_employee'.tr()),
        content: StatefulBuilder(
          builder: (context, setPickerState) {
            return SizedBox(
              width: 400,
              height: 400,
              child: Column(
                children: [
                  TextField(
                    controller: searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'search_employee_picker_hint'.tr(),
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (query) {
                      final q = query.toLowerCase().trim();
                      setPickerState(() {
                        filtered = employees.where((emp) {
                          final name = (emp['name'] as String? ?? '')
                              .toLowerCase();
                          final code = (emp['employeeCode'] as String? ?? '')
                              .toLowerCase();
                          return name.contains(q) || code.contains(q);
                        }).toList();
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(child: Text('no_employees_eligible'.tr()))
                        : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final emp = filtered[index];
                              final name =
                                  emp['name'] as String? ??
                                  'employee_default'.tr();
                              final code = emp['employeeCode'] as String? ?? '';
                              final dept = emp['department'] as String? ?? '';
                              return ListTile(
                                title: Text(name),
                                subtitle: Text('$code - $dept'),
                                onTap: () {
                                  onSelected(emp);
                                  Navigator.pop(ctx);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showCreateBalanceDialog(BuildContext context) {
    String? selectedUserId;
    Map<String, dynamic>? selectedEmp;
    LeaveType selectedType = LeaveType.annual;
    int year = selectedYear ?? DateTime.now().year;
    final entitledCtrl = TextEditingController();
    String? validationError;
    final cubit = context.read<LeaveManagementCubit>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('create_initial_balance'.tr()),
        content: StatefulBuilder(
          builder: (context, setDlgState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () {
                    _showSearchableEmployeePicker(context, (emp) {
                      setDlgState(() {
                        selectedEmp = emp;
                        selectedUserId = emp['id'] as String?;
                      });
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedEmp != null
                              ? '${selectedEmp!['name']} (${selectedEmp!['employeeCode']})'
                              : 'select_employee'.tr(),
                          style: TextStyle(
                            color: selectedEmp != null
                                ? Colors.black
                                : Colors.grey.shade600,
                            fontWeight: selectedEmp != null
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
                if (selectedUserId == null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'select_employee_required'.tr(),
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 12),
                DropdownButtonFormField<LeaveType>(
                  value: selectedType,
                  decoration: InputDecoration(labelText: 'leave_type'.tr()),
                  items: LeaveType.values
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.name.tr()),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setDlgState(() => selectedType = val);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: year,
                  decoration: InputDecoration(labelText: 'year'.tr()),
                  items: [2025, 2026, 2027, 2028]
                      .map(
                        (y) => DropdownMenuItem(
                          value: y,
                          child: Text(y.toString()),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setDlgState(() => year = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: entitledCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'annualEntitlement'.tr(),
                    errorText: validationError,
                  ),
                  onChanged: (_) {
                    if (validationError != null) {
                      setDlgState(() => validationError = null);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('cancel'.tr()),
          ),
          StatefulBuilder(
            builder: (context, setBtnState) => ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (selectedUserId == null) {
                        return;
                      }
                      final entStr = entitledCtrl.text.trim();
                      final ent = double.tryParse(entStr);
                      if (ent == null || ent <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('invalid_entitlement'.tr()),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      final ok = await cubit.createBalance(
                        userId: selectedUserId!,
                        type: selectedType,
                        year: year,
                        entitledDays: ent,
                      );
                      if (ok && ctx.mounted) {
                        Navigator.pop(ctx);
                      }
                    },
              child: Text('save'.tr()),
            ),
          ),
        ],
      ),
    );
  }

  void _showConfigDialog(BuildContext context) {
    final hrEligibleUsers = employees.where((emp) {
      final role = emp['role'] as String? ?? '';
      return role == 'hr' || role == 'hrAdmin' || role == 'superAdmin';
    }).toList();

    String? selectedHrId = config['finalHrApproverId'] as String?;
    if (selectedHrId != null &&
        !hrEligibleUsers.any((u) => u['id'] == selectedHrId)) {
      selectedHrId = null;
    }
    final cubit = context.read<LeaveManagementCubit>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('final_hr_approver_config'.tr()),
        content: StatefulBuilder(
          builder: (context, setDlgState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'final_hr_guidance'.tr(),
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                value: selectedHrId,
                decoration: InputDecoration(
                  labelText: 'final_hr_approver'.tr(),
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text('no_hr_configured'.tr()),
                  ),
                  ...hrEligibleUsers.map((u) {
                    final name =
                        u['name'] as String? ?? 'employee_default'.tr();
                    final code = u['employeeCode'] as String? ?? '';
                    final role = u['role'] as String? ?? '';
                    return DropdownMenuItem<String?>(
                      value: u['id'] as String,
                      child: Text('$name ($code) - $role'),
                    );
                  }),
                ],
                onChanged: (val) => setDlgState(() => selectedHrId = val),
              ),
            ],
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
                    final ok = await cubit.updateCompanyApprovalConfig(
                      selectedHrId,
                    );
                    if (ok && ctx.mounted) {
                      Navigator.pop(ctx);
                    }
                  },
            child: Text('save'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (balancesError != null && balances.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'failed_to_load_balances'.tr(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(balancesError!, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => onFilterChanged(
                currentPage,
                selectedYear,
                selectedDept,
                searchController.text.trim(),
              ),
              child: Text('retry'.tr()),
            ),
          ],
        ),
      );
    }

    final hrApproverName = config['finalHrApprover'] != null
        ? config['finalHrApprover']['name'] as String
        : 'not_configured'.tr();

    final canManageConfig =
        userRole == UserRole.hr ||
        userRole == UserRole.hrAdmin ||
        userRole == UserRole.superAdmin;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'balances_and_adjustments'.tr(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Text(
                    '${'final_hr_approver'.tr()}: $hrApproverName',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (canManageConfig) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.settings, color: AppColors.primary),
                      onPressed: () => _showConfigDialog(context),
                      tooltip: 'final_hr_approver_config'.tr(),
                    ),
                  ],
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: Text('create_initial_balance'.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _showCreateBalanceDialog(context),
                  ),
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
                    labelText: 'search_employee'.tr(),
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                  ),
                  onSubmitted: (val) {
                    onFilterChanged(1, selectedYear, selectedDept, val);
                  },
                ),
              ),
              const SizedBox(width: 16),
              DropdownButton<int>(
                value: selectedYear,
                items: [2025, 2026, 2027, 2028]
                    .map(
                      (y) =>
                          DropdownMenuItem(value: y, child: Text(y.toString())),
                    )
                    .toList(),
                onChanged: (val) {
                  onFilterChanged(
                    1,
                    val,
                    selectedDept,
                    searchController.text.trim(),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: balances.isEmpty
                ? Center(child: Text('no_balances_found'.tr()))
                : ListView.builder(
                    itemCount: balances.length,
                    itemBuilder: (context, index) {
                      final balance = balances[index];
                      final balanceJson = balance.toJson();
                      final userName =
                          balanceJson['user']?['name'] as String? ??
                          'employee_default'.tr();
                      final code =
                          balanceJson['user']?['employeeCode'] as String? ?? '';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(
                            '$userName ${code.isNotEmpty ? "($code)" : ""}',
                          ),
                          subtitle: Text(
                            '${'leave_type'.tr()}: ${balance.type.name.tr()} | '
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
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: () =>
                                    _showAdjustDialog(context, balance),
                                child: Text('adjust_balance'.tr()),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          // Pagination footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'total_balances'.tr(
                  namedArgs: {'count': totalBalances.toString()},
                ),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: currentPage > 1
                        ? () => onFilterChanged(
                            currentPage - 1,
                            selectedYear,
                            selectedDept,
                            searchController.text.trim(),
                          )
                        : null,
                    child: Text('previous'.tr()),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('${'page'.tr()} $currentPage / $totalPages'),
                  ),
                  TextButton(
                    onPressed: currentPage < totalPages
                        ? () => onFilterChanged(
                            currentPage + 1,
                            selectedYear,
                            selectedDept,
                            searchController.text.trim(),
                          )
                        : null,
                    child: Text('next'.tr()),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
