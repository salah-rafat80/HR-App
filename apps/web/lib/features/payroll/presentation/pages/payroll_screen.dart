import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/bloc/web_cubits.dart';
import 'package:hr_core/features/admin/domain/entities/payroll_run.dart';
import 'package:hr_core/features/admin/domain/repositories/admin_payroll_repository.dart';
import '../../../../core/di/injection.dart';

class PayrollCubit extends WebCubit<List<PayrollRun>> {
  final AdminPayrollRepository _repo;

  PayrollCubit(this._repo) : super(() => _repo.getPayrollRuns());

  Future<void> startNewRun() async {
    await _repo.createRun('September 2026');
    load();
  }

  Future<void> processRun(String id) async {
    await _repo.processRun(id);
    load();
  }

  Future<void> approveRun(String id) async {
    await _repo.approveRun(id);
    load();
  }
}

class PayrollScreen extends StatelessWidget {
  const PayrollScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PayrollCubit(getIt<AdminPayrollRepository>()),
      child: const _PayrollView(),
    );
  }
}

class _PayrollView extends StatelessWidget {
  const _PayrollView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Payroll Runs', style: Theme.of(context).textTheme.displaySmall),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => context.read<PayrollCubit>().startNewRun(),
                  icon: const Icon(Iconsax.play_cricle, size: 18),
                  label: const Text('Start New Run'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
                boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: BlocBuilder<PayrollCubit, WebState<List<PayrollRun>>>(
                builder: (ctx, state) {
                  if (state is WebLoading || state is WebInitial) return _buildShimmer(context);
                  if (state is WebError<List<PayrollRun>>) return _buildError(context, state.message);
                  if (state is WebSuccess<List<PayrollRun>>) {
                    if (state.data.isEmpty) return _buildEmpty(context);
                    return _buildTable(context, state.data);
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

  Widget _buildTable(BuildContext context, List<PayrollRun> runs) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 48),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: DataTable(
            showBottomBorder: true,
            columns: const [
              DataColumn(label: Text('PERIOD')),
              DataColumn(label: Text('STATUS')),
              DataColumn(label: Text('EMPLOYEES')),
              DataColumn(label: Text('TOTAL AMOUNT')),
              DataColumn(label: Text('ACTIONS')),
            ],
            rows: runs.asMap().entries.map((e) {
              final i = e.key;
              final r = e.value;
              final isPaid = r.status == PayrollStatus.paid || r.status == PayrollStatus.approved;
              
              Color statusColor;
              switch (r.status) {
                case PayrollStatus.paid:
                case PayrollStatus.approved:
                  statusColor = const Color(0xFF22C55E);
                  break;
                case PayrollStatus.processing:
                case PayrollStatus.pendingApproval:
                  statusColor = const Color(0xFFF59E0B);
                  break;
                default:
                  statusColor = Colors.grey;
              }

              return DataRow(
                color: WidgetStateProperty.resolveWith<Color?>((states) {
                  if (states.contains(WidgetState.hovered)) return AppColors.primary.withValues(alpha: 0.05);
                  return i.isEven ? null : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3);
                }),
                cells: [
                  DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Iconsax.calendar_2, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Text(r.periodLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ])),
                  DataCell(Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                    child: Text(r.status.name.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                  )),
                  DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Iconsax.people, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text('${r.employeeCount}'),
                  ])),
                  DataCell(Text('\$${r.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                  DataCell(Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: isPaid ? null : () {
                          if (r.status == PayrollStatus.draft) {
                            context.read<PayrollCubit>().processRun(r.id);
                          } else {
                            context.read<PayrollCubit>().approveRun(r.id);
                          }
                        },
                        child: Text(r.status == PayrollStatus.draft ? 'Process' : 'Approve'),
                      ),
                    ],
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
        columns: const [DataColumn(label: Text('PERIOD')), DataColumn(label: Text('STATUS')), DataColumn(label: Text('EMPLOYEES')), DataColumn(label: Text('TOTAL AMOUNT')), DataColumn(label: Text('ACTIONS'))],
        rows: List.generate(4, (i) => DataRow(cells: [
          DataCell(Container(width: 120, height: 16, color: Colors.white)),
          DataCell(Container(width: 80, height: 24, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)))),
          DataCell(Container(width: 40, height: 16, color: Colors.white)),
          DataCell(Container(width: 80, height: 16, color: Colors.white)),
          DataCell(Container(width: 80, height: 16, color: Colors.white)),
        ])),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(48),
      child: Center(child: Column(children: [
        Icon(Iconsax.wallet_2, size: 48, color: Colors.grey),
        SizedBox(height: 16),
        Text('No payroll runs found.', style: TextStyle(fontSize: 16, color: Colors.grey)),
      ])),
    );
  }

  Widget _buildError(BuildContext context, String msg) {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Center(child: Column(children: [
        const Icon(Iconsax.warning_2, size: 48, color: Colors.red),
        const SizedBox(height: 16),
        const Text('Failed to load payroll runs', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        Text(msg, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 16),
        ElevatedButton.icon(icon: const Icon(Iconsax.refresh), label: const Text('Retry'), onPressed: () => context.read<PayrollCubit>().load()),
      ])),
    );
  }
}
