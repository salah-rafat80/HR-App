import 'dart:html' as html;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hr_app_demo/core/di/injection.dart';

class HrReportsScreen extends StatefulWidget {
  const HrReportsScreen({super.key});
  @override
  State<HrReportsScreen> createState() => _HrReportsScreenState();
}

class _HrReportsScreenState extends State<HrReportsScreen> {
  final Dio _dio = getIt<Dio>();
  final _department = TextEditingController();
  late String _month;
  Future<Map<String, dynamic>>? _report;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    _load();
  }

  @override
  void dispose() {
    _department.dispose();
    super.dispose();
  }

  Map<String, dynamic> get _query => {
    'month': _month,
    if (_department.text.trim().isNotEmpty)
      'department': _department.text.trim(),
  };

  void _load() => setState(() => _report = _fetch());

  Future<Map<String, dynamic>> _fetch() async {
    final response = await _dio.get(
      '/hr-reports/monthly',
      queryParameters: _query,
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<void> _export() async {
    try {
      final response = await _dio.get<List<int>>(
        '/hr-reports/monthly/export',
        queryParameters: _query,
        options: Options(responseType: ResponseType.bytes),
      );
      final blob = html.Blob([
        response.data!,
      ], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..download = 'hr-monthly-report-$_month.xlsx'
        ..click();
      html.Url.revokeObjectUrl(url);
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Excel export failed.'),
            backgroundColor: Colors.red,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(32),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'HR monthly reports',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            SizedBox(
              width: 150,
              child: TextFormField(
                initialValue: _month,
                decoration: const InputDecoration(labelText: 'Month (YYYY-MM)'),
                onChanged: (value) => _month = value,
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 220,
              child: TextField(
                controller: _department,
                decoration: const InputDecoration(
                  labelText: 'Department (optional)',
                ),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(onPressed: _load, child: const Text('Apply')),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: _export,
              icon: const Icon(Icons.download),
              label: const Text('Export Excel'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: FutureBuilder<Map<String, dynamic>>(
            future: _report,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done)
                return const Center(child: CircularProgressIndicator());
              if (snapshot.hasError)
                return const Center(child: Text('Unable to load report.'));
              final totals = Map<String, dynamic>.from(
                snapshot.data!['totals'] as Map,
              );
              return ListView(
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: totals.entries
                        .map(
                          (entry) => Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text('${entry.key}: ${entry.value}'),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Employee summary',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DataTable(
                    columns: const [
                      DataColumn(label: Text('Employee')),
                      DataColumn(label: Text('Department')),
                      DataColumn(label: Text('Present')),
                      DataColumn(label: Text('Absent')),
                      DataColumn(label: Text('Overtime hours')),
                    ],
                    rows: (snapshot.data!['employees'] as List).map((value) {
                      final employee = Map<String, dynamic>.from(value as Map);
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(employee['employeeName']?.toString() ?? ''),
                          ),
                          DataCell(
                            Text(employee['department']?.toString() ?? ''),
                          ),
                          DataCell(Text(employee['presentDays'].toString())),
                          DataCell(Text(employee['absentDays'].toString())),
                          DataCell(
                            Text(
                              ((employee['overtimeMinutes'] as num) / 60)
                                  .toStringAsFixed(1),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    ),
  );
}
