import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hr_core/features/admin/domain/entities/system_config_entities.dart';

import '../../../../core/bloc/web_cubits.dart';
import '../../../../core/widgets/web_shimmer_loading.dart';
import '../bloc/system_config_cubit.dart';
import 'system_config_settings_card.dart';

class EmployeeBranchAssignments extends StatelessWidget {
  const EmployeeBranchAssignments({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SystemConfigCubit, WebState<SystemConfigState>>(
      builder: (context, state) {
        if (state is WebError<SystemConfigState>) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(state.message, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.read<SystemConfigCubit>().load(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        if (state is! WebSuccess<SystemConfigState>) {
          return const ShimmerLoading();
        }
        final employees = state.data.branchAssignedEmployees;
        final branches = state.data.branches
            .where((branch) => branch.isActive)
            .toList();
        return SettingsCard(
          title: 'Employee branch assignment',
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Attendance and overtime are accepted only inside the assigned branch.',
                ),
                const SizedBox(height: 16),
                if (employees.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('No active employees found.'),
                  )
                else
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Employee')),
                        DataColumn(label: Text('Department')),
                        DataColumn(label: Text('Assigned branch')),
                      ],
                      rows: employees
                          .map(
                            (employee) => DataRow(
                              cells: [
                                DataCell(
                                  Text(
                                    '${employee.name} (${employee.employeeCode})',
                                  ),
                                ),
                                DataCell(
                                  Text(employee.department ?? 'Unassigned'),
                                ),
                                DataCell(
                                  DropdownButton<String>(
                                    value:
                                        branches.any(
                                          (branch) =>
                                              branch.id == employee.branchId,
                                        )
                                        ? employee.branchId
                                        : null,
                                    hint: const Text('Select branch'),
                                    items: branches
                                        .map(
                                          (branch) => DropdownMenuItem(
                                            value: branch.id,
                                            child: Text(branch.name),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (branchId) async {
                                      if (branchId == null ||
                                          branchId == employee.branchId)
                                        return;
                                      try {
                                        await context
                                            .read<SystemConfigCubit>()
                                            .assignUserBranch(
                                              employee.id,
                                              branchId,
                                            );
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Employee branch updated.',
                                                  ),
                                                ),
                                              );
                                        }
                                      } catch (_) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Unable to update employee branch.',
                                                  ),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                        }
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
