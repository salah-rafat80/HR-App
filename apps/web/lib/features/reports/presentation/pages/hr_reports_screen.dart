import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/hr_reports_cubit.dart';

class HrReportsScreen extends StatefulWidget {
  const HrReportsScreen({super.key});

  @override
  State<HrReportsScreen> createState() => _HrReportsScreenState();
}

class _HrReportsScreenState extends State<HrReportsScreen> {
  final TextEditingController _monthController = TextEditingController(text: '2026-08');
  final TextEditingController _employeeIdController = TextEditingController();
  String _selectedDepartment = 'All';

  final List<String> _departments = ['All', 'IT', 'HR', 'الحسابات'];

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  @override
  void dispose() {
    _monthController.dispose();
    _employeeIdController.dispose();
    super.dispose();
  }

  void _loadReport() {
    context.read<HrReportsCubit>().fetchReport(
          month: _monthController.text.trim(),
          department: _selectedDepartment,
          employeeId: _employeeIdController.text.trim(),
        );
  }

  void _exportExcel() {
    context.read<HrReportsCubit>().exportExcel(
          month: _monthController.text.trim(),
          department: _selectedDepartment,
          employeeId: _employeeIdController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HR Monthly Attendance & Overtime Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReport,
          ),
        ],
      ),
      body: BlocConsumer<HrReportsCubit, HrReportsState>(
        listener: (context, state) {
          if (state is HrReportsExportSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Excel Report downloaded: ${state.filename}'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is HrReportsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filter Card
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        SizedBox(
                          width: 160,
                          child: TextField(
                            controller: _monthController,
                            decoration: const InputDecoration(
                              labelText: 'Month (YYYY-MM)',
                              hintText: '2026-08',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 180,
                          child: DropdownButtonFormField<String>(
                            value: _selectedDepartment,
                            decoration: const InputDecoration(
                              labelText: 'Department',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: _departments.map((dept) {
                              return DropdownMenuItem(
                                value: dept,
                                child: Text(dept),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedDepartment = val);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 180,
                          child: TextField(
                            controller: _employeeIdController,
                            decoration: const InputDecoration(
                              labelText: 'Employee ID (optional)',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.search),
                          label: const Text('Filter'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(120, 48),
                          ),
                          onPressed: _loadReport,
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          icon: state is HrReportsExporting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.download),
                          label: const Text('Export Excel'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(150, 48),
                          ),
                          onPressed: state is HrReportsExporting ? null : _exportExcel,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                if (state is HrReportsLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(48.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),

                if (state is HrReportsLoaded) ...[
                  // Summary Metric Cards
                  Row(
                    children: [
                      _buildMetricCard(
                        'Total Employees',
                        '${state.reportData.summary.totalEmployees}',
                        Icons.people,
                        Colors.blue,
                      ),
                      const SizedBox(width: 16),
                      _buildMetricCard(
                        'Total Work Days',
                        '${state.reportData.summary.totalWorkDays}',
                        Icons.calendar_month,
                        Colors.indigo,
                      ),
                      const SizedBox(width: 16),
                      _buildMetricCard(
                        'Present Days',
                        '${state.reportData.summary.totalPresent}',
                        Icons.check_circle,
                        Colors.green,
                      ),
                      const SizedBox(width: 16),
                      _buildMetricCard(
                        'Absent Days',
                        '${state.reportData.summary.totalAbsent}',
                        Icons.cancel,
                        Colors.red,
                      ),
                      const SizedBox(width: 16),
                      _buildMetricCard(
                        'Overtime Hours',
                        '${state.reportData.summary.totalOvertimeHours.toStringAsFixed(1)} hrs',
                        Icons.timer,
                        Colors.orange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Employee Breakdown Table
                  const Text(
                    'Employee Summary Breakdown',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  Card(
                    elevation: 2,
                    child: SizedBox(
                      width: double.infinity,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Employee Code')),
                          DataColumn(label: Text('Name')),
                          DataColumn(label: Text('Department')),
                          DataColumn(label: Text('Present Days')),
                          DataColumn(label: Text('Absent Days')),
                          DataColumn(label: Text('Overtime Hours')),
                          DataColumn(label: Text('Overtime Pay')),
                        ],
                        rows: state.reportData.employees.map((emp) {
                          return DataRow(cells: [
                            DataCell(Text(emp.employeeCode.isEmpty ? emp.employeeId : emp.employeeCode)),
                            DataCell(Text(emp.name)),
                            DataCell(Text(emp.department)),
                            DataCell(Text('${emp.presentDays}')),
                            DataCell(Text('${emp.absentDays}')),
                            DataCell(Text('${emp.overtimeHours.toStringAsFixed(1)} hrs')),
                            DataCell(Text('\$${emp.overtimePay.toStringAsFixed(2)}')),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  Icon(icon, color: color, size: 20),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
