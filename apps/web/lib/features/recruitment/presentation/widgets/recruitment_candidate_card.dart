import 'package:flutter/material.dart';
import 'package:hr_core/features/admin/domain/entities/recruitment_entities.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

class CandidateCard extends StatelessWidget {
  final Candidate c;
  final bool isDragging;

  const CandidateCard(this.c, {super.key, this.isDragging = false});

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
