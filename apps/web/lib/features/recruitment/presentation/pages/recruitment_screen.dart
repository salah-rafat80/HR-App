import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hr_core/features/admin/domain/entities/recruitment_entities.dart';
import 'package:hr_core/features/admin/domain/repositories/recruitment_repository.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../core/bloc/web_cubits.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/recruitment_cubit.dart';
import '../widgets/recruitment_kanban_column.dart';

class RecruitmentScreen extends StatelessWidget {
  const RecruitmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RecruitmentCubit(getIt<RecruitmentRepository>()),
      child: const _RecruitmentView(),
    );
  }
}

class _RecruitmentView extends StatelessWidget {
  const _RecruitmentView();

  static const _columns = ['applied', 'screening', 'interview', 'offer', 'hired'];
  static const _columnLabels = ['Applied', 'Screening', 'Interview', 'Offer', 'Hired'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recruitment Pipeline', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: () => _showPostJobDialog(context),
                  icon: const Icon(Iconsax.add),
                  label: const Text('Post New Job'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: BlocBuilder<RecruitmentCubit, WebState<List<Candidate>>>(
                builder: (context, state) {
                  if (state is WebLoading || state is WebInitial) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is WebError<List<Candidate>>) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Iconsax.warning_2, size: 48, color: Colors.red),
                          const SizedBox(height: 16),
                          Text('Error: ${state.message}'),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            icon: const Icon(Iconsax.refresh),
                            label: const Text('Retry'),
                            onPressed: () => context.read<RecruitmentCubit>().load(),
                          ),
                        ],
                      ),
                    );
                  }
                  if (state is WebSuccess<List<Candidate>>) {
                    final candidates = state.data;
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (int i = 0; i < _columns.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(right: 16),
                              child: KanbanColumn(
                                stageKey: _columns[i],
                                title: _columnLabels[i],
                                candidates: candidates.where((c) => c.stage.name == _columns[i]).toList(),
                              ),
                            ),
                        ],
                      ),
                    );
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

  void _showPostJobDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    String selectedDept = 'Engineering';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Post New Job'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Job Title')),
            const SizedBox(height: 16),
            StatefulBuilder(
              builder: (ctx, setState) => DropdownButtonFormField<String>(
                value: selectedDept,
                decoration: const InputDecoration(labelText: 'Department'),
                items: ['Engineering', 'Sales', 'HR', 'Finance', 'Marketing']
                    .map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                onChanged: (v) => setState(() => selectedDept = v!),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (titleCtrl.text.isNotEmpty) {
                context.read<RecruitmentCubit>().postNewJob(titleCtrl.text, selectedDept);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }
}




