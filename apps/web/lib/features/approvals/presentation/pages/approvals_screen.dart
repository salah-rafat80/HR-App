import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hr_core/features/leave/domain/entities/leave_request.dart';
import 'package:hr_core/features/leave/domain/repositories/leave_repository.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/bloc/web_cubits.dart';
import '../../../../core/di/injection.dart';
import '../bloc/approvals_cubit.dart';
import '../widgets/approvals_data_table.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;



class ApprovalsScreen extends StatelessWidget {
  const ApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = getIt<SharedPreferences>();
    final userId = prefs.getString('user_id') ?? '';
    final role = prefs.getString('user_role') ?? '';

    return BlocProvider(
      create: (_) => ApprovalsCubit(getIt<LeaveRepository>(), getIt<io.Socket>(), userId, role),

      child: const _ApprovalsView(),
    );
  }
}

class _ApprovalsView extends StatelessWidget {
  const _ApprovalsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pending Approvals',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: BlocBuilder<ApprovalsCubit, WebState<List<LeaveRequest>>>(
                builder: (context, state) {
                  if (state is WebLoading || state is WebInitial) {
                    return _buildShimmerTable(context);
                  }
                  if (state is WebError<List<LeaveRequest>>) {
                    return _buildErrorState(context, state.message);
                  }
                  if (state is WebSuccess<List<LeaveRequest>>) {
                    if (state.data.isEmpty) {
                      return _buildEmptyState(context);
                    }
                    return ApprovalsDataTable(items: state.data);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerTable(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;
    
    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Employee')),
          DataColumn(label: Text('Request Type')),
          DataColumn(label: Text('Duration')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Actions')),
        ],
        rows: List.generate(4, (index) => DataRow(
          cells: [
            DataCell(Container(width: 100, height: 16, color: Colors.white)),
            DataCell(Container(width: 80, height: 16, color: Colors.white)),
            DataCell(Container(width: 120, height: 16, color: Colors.white)),
            DataCell(Container(width: 60, height: 24, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)))),
            DataCell(Container(width: 80, height: 24, color: Colors.white)),
          ],
        )),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        children: [
          const Icon(Iconsax.tick_square, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text('You\'re all caught up!', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text('There are no pending approvals at the moment.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        children: [
          const Icon(Iconsax.warning_2, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Failed to load approvals', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Iconsax.refresh),
            label: const Text('Retry'),
            onPressed: () => context.read<ApprovalsCubit>().load(),
          ),
        ],
      ),
    );
  }
}
