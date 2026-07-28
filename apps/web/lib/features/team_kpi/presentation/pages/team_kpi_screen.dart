import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/bloc/web_cubits.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hr_core/features/kpi/domain/repositories/kpi_repository.dart';
import 'package:hr_core/features/team/domain/entities/team_member.dart';
import '../../../../core/di/injection.dart';
import '../bloc/team_kpi_cubit.dart';
import '../widgets/team_kpi_table_content.dart';



class TeamKpiScreen extends StatelessWidget {
  const TeamKpiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TeamKpiCubit(getIt<KpiRepository>()),
      child: const _TeamKpiView(),
    );
  }
}

class _TeamKpiView extends StatefulWidget {
  const _TeamKpiView();
  @override
  State<_TeamKpiView> createState() => _TeamKpiViewState();
}

class _TeamKpiViewState extends State<_TeamKpiView> {
  String _selectedDept = 'All';
  final _depts = ['All', 'Engineering', 'Sales', 'HR', 'Finance', 'Product'];

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
                Text('KPI Overview', style: Theme.of(context).textTheme.displaySmall),
                const Spacer(),
                DropdownButton<String>(
                  value: _selectedDept,
                  underline: const SizedBox.shrink(),
                  borderRadius: BorderRadius.circular(12),
                  items: _depts.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                  onChanged: (v) => setState(() => _selectedDept = v!),
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
              child: BlocBuilder<TeamKpiCubit, WebState<List<TeamMember>>>(
                builder: (ctx, state) {
                  if (state is WebLoading || state is WebInitial) return const Center(child: CircularProgressIndicator());
                  if (state is WebError<List<TeamMember>>) return Center(child: Text('Error: ${state.message}'));
                  if (state is WebSuccess<List<TeamMember>>) {
                    final rows = _selectedDept == 'All'
                        ? state.data
                        : state.data.where((r) => r.department == _selectedDept).toList();
                    return TeamKpiTableContent(rows: rows, selectedDept: _selectedDept);
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

  }
