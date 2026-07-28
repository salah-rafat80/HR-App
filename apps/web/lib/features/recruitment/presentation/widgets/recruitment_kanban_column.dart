import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hr_core/features/admin/domain/entities/recruitment_entities.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/recruitment_cubit.dart';
import 'recruitment_candidate_card.dart';

class KanbanColumn extends StatelessWidget {
  final String stageKey;
  final String title;
  final List<Candidate> candidates;

  const KanbanColumn({super.key, required this.stageKey, required this.title, required this.candidates});

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
                            feedback: Material(elevation: 8, borderRadius: BorderRadius.circular(12), child: SizedBox(width: 268, child: CandidateCard(c, isDragging: true))),
                            childWhenDragging: Opacity(opacity: 0.3, child: CandidateCard(c)),
                            child: CandidateCard(c),
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
