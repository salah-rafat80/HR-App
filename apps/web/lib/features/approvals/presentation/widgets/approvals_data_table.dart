import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hr_core/features/leave/domain/entities/leave_enums.dart';
import 'package:hr_core/features/leave/domain/entities/leave_request.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../bloc/approvals_cubit.dart';

class ApprovalsDataTable extends StatelessWidget {
  final List<LeaveRequest> items;

  const ApprovalsDataTable({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        dataTableTheme: DataTableThemeData(
          headingRowColor: WidgetStateProperty.all(Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)),
          dataRowColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
            if (states.contains(WidgetState.hovered)) {
              return Theme.of(context).colorScheme.primary.withValues(alpha: 0.05);
            }
            return null; // Use the default value.
          }),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 48), // minus padding
          child: DataTable(
            headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            showBottomBorder: true,
            columns: const [
              DataColumn(label: Text('Employee')),
              DataColumn(label: Text('Request Type')),
              DataColumn(label: Text('Duration')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Actions')),
            ],
            rows: items.map((item) => _buildRow(context, item)).toList(),
          ),
        ),
      ),
    );
  }

  DataRow _buildRow(BuildContext context, LeaveRequest req) {
    final cubit = context.read<ApprovalsCubit>();
    final isFlight = cubit.isInFlight(req.id);
    final isPending = req.overallStatus == LeaveStatus.pending;
    
    return DataRow(
      cells: [
        DataCell(Text(req.employeeName ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600))),
        DataCell(Text(req.type.name)),
        DataCell(Text('${req.startDate.toString().split(' ')[0]} - ${req.endDate.toString().split(' ')[0]}')),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isPending ? Colors.orange.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(req.displayStatus.toUpperCase(), style: TextStyle(color: isPending ? Colors.orange : Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ),
        DataCell(
          isFlight 
            ? const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              )
            : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Iconsax.tick_circle, color: isPending ? Colors.green : Colors.grey),
                tooltip: 'Approve',
                onPressed: isPending ? () => cubit.approve(req.id, onError: (e) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')))) : null,
              ),
              IconButton(
                icon: Icon(Iconsax.close_circle, color: isPending ? Colors.red : Colors.grey),
                tooltip: 'Reject',
                onPressed: isPending ? () => cubit.reject(req.id, onError: (e) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')))) : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
