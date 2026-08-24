import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/bloc/web_cubits.dart';
import '../../../../core/widgets/web_shimmer_loading.dart';
import '../bloc/system_config_cubit.dart';
import 'system_config_settings_card.dart';

class EmployeeHierarchyAssignments extends StatelessWidget {
  const EmployeeHierarchyAssignments({super.key});

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
        final departments = state.data.departments;

        // Managers/Team Leads: Any active user whose role is team_lead or manager
        final eligibleManagers = employees
            .where(
              (emp) =>
                  emp.role.toLowerCase() == 'team_lead' ||
                  emp.role.toLowerCase() == 'teamlead' ||
                  emp.role.toLowerCase() == 'manager',
            )
            .toList();

        return SettingsCard(
          title: 'Employee Department & Manager Assignment',
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Assign employee departments and direct managers. The direct manager must belong to the same department to approve leave requests.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 20),
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
                        DataColumn(label: Text('Role')),
                        DataColumn(label: Text('Department')),
                        DataColumn(label: Text('Direct Manager (TL)')),
                      ],
                      rows: employees.map((employee) {
                        return DataRow(
                          cells: [
                            DataCell(
                              Text(
                                '${employee.name} (${employee.employeeCode})',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                employee.role.toUpperCase(),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            DataCell(
                              DropdownButton<String>(
                                value:
                                    departments.any(
                                      (dept) =>
                                          dept.name == employee.department,
                                    )
                                    ? employee.department
                                    : null,
                                hint: const Text('Select Dept'),
                                items: departments.map((dept) {
                                  return DropdownMenuItem(
                                    value: dept.name,
                                    child: Text(dept.name),
                                  );
                                }).toList(),
                                onChanged: (deptName) async {
                                  if (deptName == employee.department) return;
                                  try {
                                    await context
                                        .read<SystemConfigCubit>()
                                        .updateUserHierarchy(
                                          employee.id,
                                          deptName,
                                          employee.managerId,
                                        );
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Department updated.'),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Failed: ${e.toString()}',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                            ),
                            DataCell(
                              DropdownButton<String>(
                                value:
                                    eligibleManagers.any(
                                      (mgr) =>
                                          mgr.id == employee.managerId &&
                                          mgr.id != employee.id,
                                    )
                                    ? employee.managerId
                                    : null,
                                hint: const Text('No Manager'),
                                items: [
                                  const DropdownMenuItem<String>(
                                    value: null,
                                    child: Text('None (Clear)'),
                                  ),
                                  ...eligibleManagers
                                      .where((mgr) => mgr.id != employee.id)
                                      .map((mgr) {
                                        return DropdownMenuItem(
                                          value: mgr.id,
                                          child: Text(
                                            '${mgr.name} (${mgr.department ?? "No Dept"})',
                                          ),
                                        );
                                      }),
                                ],
                                onChanged: (managerId) async {
                                  if (managerId == employee.managerId) return;
                                  try {
                                    await context
                                        .read<SystemConfigCubit>()
                                        .updateUserHierarchy(
                                          employee.id,
                                          employee.department,
                                          managerId,
                                        );
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Manager updated.'),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Failed: ${e.toString()}',
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
                        );
                      }).toList(),
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
