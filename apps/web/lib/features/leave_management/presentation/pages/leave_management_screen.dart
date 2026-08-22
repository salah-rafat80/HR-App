import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hr_core/features/leave/domain/entities/leave_enums.dart';
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

    final isAllowed =
        userRole == UserRole.hr ||
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
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text('only_hr_allowed'.tr()),
            ],
          ),
        ),
      );
    }

    return BlocProvider(
      create: (context) =>
          LeaveManagementCubit(getIt<LeaveRepository>())
            ..loadDashboard(year: _selectedYear),
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text(
              'leave_management_dashboard'.tr(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
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
          body: BlocConsumer<LeaveManagementCubit, LeaveManagementState>(
            listener: (context, state) {
              if (state is LeaveManagementLoaded && state.actionError != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.actionError!),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            builder: (context, state) {
              if (state is LeaveManagementInitial ||
                  state is LeaveManagementLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is LeaveManagementError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(state.message),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context
                            .read<LeaveManagementCubit>()
                            .loadDashboard(year: _selectedYear),
                        child: Text('retry'.tr()),
                      ),
                    ],
                  ),
                );
              }

              if (state is LeaveManagementLoaded) {
                return TabBarView(
                  children: [
                    _PoliciesTab(
                      policies: state.policies,
                      policiesError: state.policiesError,
                      isSubmitting: state.isSubmitting,
                    ),
                    _BalancesTab(
                      balances: state.balances,
                      balancesError: state.balancesError,
                      selectedYear: _selectedYear,
                      searchController: _searchController,
                      selectedDept: _selectedDept,
                      onFilterChanged: (targetPage, year, dept, search) {
                        setState(() {
                          _selectedYear = year;
                          _selectedDept = dept;
                        });
                        context.read<LeaveManagementCubit>().refreshBalances(
                          page: targetPage,
                          year: year,
                          department: dept,
                          employeeId: search.isEmpty ? null : search,
                        );
                      },
                      config: state.config,
                      employees: state.employees,
                      userRole: userRole,
                      currentPage: state.currentBalancesPage,
                      totalPages: state.totalBalancesPages,
                      totalBalances: state.totalBalances,
                      isSubmitting: state.isSubmitting,
                    ),
                    _PendingRequestsTab(
                      requests: state.pendingRequests,
                      pendingRequestsError: state.pendingRequestsError,
                      isSubmitting: state.isSubmitting,
                    ),
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
  final String? policiesError;
  final bool isSubmitting;

  const _PoliciesTab({
    required this.policies,
    this.policiesError,
    required this.isSubmitting,
  });

  void _showPolicyFormDialog(
    BuildContext context, {
    LeavePolicy? existingPolicy,
  }) {
    LeaveType selectedType = existingPolicy?.type ?? LeaveType.annual;
    final nameCtrl = TextEditingController(
      text: existingPolicy?.displayNameAr ?? '',
    );
    final entitlementCtrl = TextEditingController(
      text: existingPolicy != null
          ? existingPolicy.annualEntitlement.toString()
          : '',
    );
    final noticeCtrl = TextEditingController(
      text: existingPolicy != null
          ? existingPolicy.minimumNoticeDays.toString()
          : '',
    );
    bool isPaid = existingPolicy?.isPaid ?? true;
    bool requiresBalance = existingPolicy?.requiresBalance ?? true;
    bool allowHalfDay = existingPolicy?.allowHalfDay ?? true;
    bool requiresReason = existingPolicy?.requiresReason ?? true;
    bool isActive = existingPolicy?.isActive ?? true;

    String? nameError;
    String? entitlementError;
    String? noticeError;

    final cubit = context.read<LeaveManagementCubit>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          existingPolicy == null
              ? 'create_leave_policy'.tr()
              : 'edit_leave_policy'.tr(),
        ),
        content: StatefulBuilder(
          builder: (context, setDlgState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (existingPolicy == null)
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
                      if (val != null) {
                        setDlgState(() {
                          selectedType = val;
                        });
                      }
                    },
                  )
                else
                  Text(
                    '${'leave_type'.tr()}: ${existingPolicy.type.name.tr()}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'displayNameAr'.tr(),
                    errorText: nameError,
                  ),
                  onChanged: (_) {
                    if (nameError != null) setDlgState(() => nameError = null);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: entitlementCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'annualEntitlement'.tr(),
                    errorText: entitlementError,
                  ),
                  onChanged: (_) {
                    if (entitlementError != null)
                      setDlgState(() => entitlementError = null);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noticeCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'minimumNoticeDays'.tr(),
                    errorText: noticeError,
                  ),
                  onChanged: (_) {
                    if (noticeError != null)
                      setDlgState(() => noticeError = null);
                  },
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  title: Text('isPaid'.tr()),
                  value: isPaid,
                  onChanged: (v) => setDlgState(() => isPaid = v ?? true),
                ),
                CheckboxListTile(
                  title: Text('requiresBalance'.tr()),
                  value: requiresBalance,
                  onChanged: (v) =>
                      setDlgState(() => requiresBalance = v ?? true),
                ),
                CheckboxListTile(
                  title: Text('allowHalfDay'.tr()),
                  value: allowHalfDay,
                  onChanged: (v) =>
                      setDlgState(() => allowHalfDay = v ?? false),
                ),
                CheckboxListTile(
                  title: Text('requiresReason'.tr()),
                  value: requiresReason,
                  onChanged: (v) =>
                      setDlgState(() => requiresReason = v ?? true),
                ),
                CheckboxListTile(
                  title: Text('isActive'.tr()),
                  value: isActive,
                  onChanged: (v) => setDlgState(() => isActive = v ?? true),
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
                      final nameStr = nameCtrl.text.trim();
                      final ent = double.tryParse(entitlementCtrl.text.trim());
                      final notice = int.tryParse(noticeCtrl.text.trim());

                      bool isValid = true;
                      if (nameStr.isEmpty) {
                        nameError = 'display_name_required'.tr();
                        isValid = false;
                      }
                      if (ent == null || ent <= 0) {
                        entitlementError = 'invalid_entitlement'.tr();
                        isValid = false;
                      }
                      if (notice == null || notice < 0) {
                        noticeError = 'invalid_notice_days'.tr();
                        isValid = false;
                      }

                      if (!isValid) {
                        setBtnState(() {});
                        return;
                      }

                      bool ok = false;
                      if (existingPolicy == null) {
                        final policy = LeavePolicy(
                          id: '',
                          type: selectedType,
                          displayNameAr: nameStr,
                          annualEntitlement: ent!,
                          isPaid: isPaid,
                          requiresBalance: requiresBalance,
                          allowHalfDay: allowHalfDay,
                          minimumNoticeDays: notice!,
                          requiresReason: requiresReason,
                          isActive: isActive,
                        );
                        ok = await cubit.createPolicy(policy);
                      } else {
                        ok = await cubit.updatePolicy(existingPolicy.type, {
                          'displayNameAr': nameStr,
                          'annualEntitlement': ent!,
                          'isPaid': isPaid,
                          'requiresBalance': requiresBalance,
                          'allowHalfDay': allowHalfDay,
                          'minimumNoticeDays': notice!,
                          'requiresReason': requiresReason,
                          'isActive': isActive,
                        });
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
                  : Text('save'.tr()),
            ),
          ),
        ],
      ),
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

// Balances Tab
class _BalancesTab extends StatelessWidget {
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

  const _BalancesTab({
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

// Pending Requests Tab
class _PendingRequestsTab extends StatelessWidget {
  final List<LeaveRequest> requests;
  final String? pendingRequestsError;
  final bool isSubmitting;

  const _PendingRequestsTab({
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
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
