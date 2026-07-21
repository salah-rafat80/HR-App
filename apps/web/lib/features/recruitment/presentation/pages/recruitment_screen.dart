import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hr_core/features/admin/domain/entities/recruitment_entities.dart';
import 'package:hr_core/features/admin/domain/repositories/recruitment_repository.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../core/bloc/web_cubits.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/recruitment_cubit.dart';

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
                              child: _KanbanColumn(
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

class _KanbanColumn extends StatelessWidget {
  final String stageKey;
  final String title;
  final List<Candidate> candidates;

  const _KanbanColumn({required this.stageKey, required this.title, required this.candidates});

  @override
  Widget build(BuildContext context) {
    return DragTarget<Candidate>(
      onWillAcceptWithDetails: (details) => details.data.stage.name != stageKey,
      onAcceptWithDetails: (details) {
        final newStage = CandidateStage.values.firstWhere((s) => s.name == stageKey, orElse: () => details.data.stage);
        context.read<RecruitmentCubit>().moveCandidate(details.data.id, newStage);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 300,
          decoration: BoxDecoration(
            color: isHovered ? AppColors.primary.withValues(alpha: 0.05) : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isHovered ? AppColors.primary.withValues(alpha: 0.5) : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: isHovered ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('${candidates.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: candidates.isEmpty
                    ? Center(child: Text('No candidates', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5))))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: candidates.length,
                        itemBuilder: (context, index) {
                          final c = candidates[index];
                          return Draggable<Candidate>(
                            data: c,
                            feedback: Material(elevation: 8, borderRadius: BorderRadius.circular(12), child: SizedBox(width: 268, child: _CandidateCard(c, isDragging: true))),
                            childWhenDragging: Opacity(opacity: 0.3, child: _CandidateCard(c)),
                            child: _CandidateCard(c),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CandidateCard extends StatelessWidget {
  final Candidate c;
  final bool isDragging;

  const _CandidateCard(this.c, {this.isDragging = false});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isDragging ? 8 : 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
      shadowColor: Colors.black.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 4),
            Text('Job: ${c.jobId}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Iconsax.tag, size: 12, color: _stageColor(c.stage)),
                    const SizedBox(width: 4),
                    Text(c.stage.name, style: TextStyle(color: _stageColor(c.stage), fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
                const Icon(Iconsax.more, size: 16, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _stageColor(CandidateStage stage) {
    switch (stage) {
      case CandidateStage.applied: return Colors.blue;
      case CandidateStage.screening: return Colors.orange;
      case CandidateStage.interview: return Colors.purple;
      case CandidateStage.offer: return Colors.teal;
      case CandidateStage.hired: return Colors.green;
      case CandidateStage.rejected: return Colors.red;
    }
  }
}
