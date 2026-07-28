import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hr_core/features/team/domain/entities/team_member.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/team_kpi_cubit.dart';

class TeamKpiTableContent extends StatelessWidget {
  final List<TeamMember> rows;
  final String selectedDept;

  const TeamKpiTableContent({super.key, required this.rows, required this.selectedDept});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return _buildEmpty(context);
    return _buildTable(context, rows);
  }

  void _showAssignDialog(BuildContext context, TeamMember member) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Assign KPI to ${member.name}'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'KPI Title'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.isNotEmpty) {
                context.read<TeamKpiCubit>().assignKpi(member.id, ctrl.text);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('KPI Assigned to ${member.name}')));
              }
            },
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }

    Widget _buildTable(BuildContext context, List<TeamMember> rows) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 48),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: DataTable(
            showBottomBorder: true,
            columns: const [
              DataColumn(label: Text('EMPLOYEE')),
              DataColumn(label: Text('DEPARTMENT')),
              DataColumn(label: Text('ROLE')),
              DataColumn(label: Text('KPI SCORE')),
              DataColumn(label: Text('ACTIONS')),
            ],
            rows: rows.asMap().entries.map((entry) {
              final i = entry.key;
              final r = entry.value;
              final isEven = i.isEven;
              final score = (r.kpiScorePercent * 100).round();
              final scoreColor = score >= 85 ? const Color(0xFF22C55E) : score >= 70 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444);

              return DataRow(
                color: WidgetStateProperty.resolveWith<Color?>((states) {
                  if (states.contains(WidgetState.hovered)) return AppColors.primary.withValues(alpha: 0.05);
                  return isEven ? null : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3);
                }),
                cells: [
                  DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                    CircleAvatar(radius: 16, backgroundColor: AppColors.primary.withValues(alpha: 0.1), child: Text(r.name[0], style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13))),
                    const SizedBox(width: 12),
                    Text(r.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ])),
                  DataCell(Text(r.department)),
                  DataCell(Text(r.title, style: const TextStyle(color: Colors.grey))),
                  DataCell(SizedBox(width: 150, child: Row(children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: r.kpiScorePercent,
                          minHeight: 8,
                          backgroundColor: scoreColor.withValues(alpha: 0.15),
                          valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('$score', style: TextStyle(fontWeight: FontWeight.bold, color: scoreColor)),
                  ]))),
                  DataCell(TextButton(
                    onPressed: () => _showAssignDialog(context, r),
                    child: const Text('Assign KPI'),
                  )),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

    Widget _buildShimmer(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: DataTable(
        columns: const [DataColumn(label: Text('EMPLOYEE')), DataColumn(label: Text('DEPARTMENT')), DataColumn(label: Text('ROLE')), DataColumn(label: Text('KPI SCORE')), DataColumn(label: Text('TREND'))],
        rows: List.generate(5, (i) => DataRow(cells: [
          DataCell(Container(width: 140, height: 16, color: Colors.white)),
          DataCell(Container(width: 80, height: 16, color: Colors.white)),
          DataCell(Container(width: 100, height: 16, color: Colors.white)),
          DataCell(Container(width: 120, height: 16, color: Colors.white)),
          DataCell(Container(width: 40, height: 16, color: Colors.white)),
        ])),
      ),
    );
  }

    Widget _buildEmpty(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Center(child: Column(children: [
        const Icon(Iconsax.chart_2, size: 48, color: Colors.grey),
        const SizedBox(height: 16),
        Text('No team members in "$selectedDept"', style: const TextStyle(fontSize: 16, color: Colors.grey)),
      ])),
    );
  }

    Widget _buildError(BuildContext context, String msg) {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Center(child: Column(children: [
        const Icon(Iconsax.warning_2, size: 48, color: Colors.red),
        const SizedBox(height: 16),
        Text('Failed to load KPI data', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(msg, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 16),
        ElevatedButton.icon(icon: const Icon(Iconsax.refresh), label: const Text('Retry'), onPressed: () => context.read<TeamKpiCubit>().load()),
      ])),
    );
  }


}

