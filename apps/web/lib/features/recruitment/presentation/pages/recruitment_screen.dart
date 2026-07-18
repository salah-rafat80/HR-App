import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

class Candidate {
  final String id;
  final String name;
  final String role;
  final String time;
  String status;

  Candidate({required this.id, required this.name, required this.role, required this.time, required this.status});
}

class RecruitmentScreen extends StatefulWidget {
  const RecruitmentScreen({super.key});

  @override
  State<RecruitmentScreen> createState() => _RecruitmentScreenState();
}

class _RecruitmentScreenState extends State<RecruitmentScreen> {
  final List<Candidate> candidates = [
    Candidate(id: '1', name: 'John Doe', role: 'Senior Flutter Dev', time: '2d ago', status: 'Applied'),
    Candidate(id: '2', name: 'Sarah Smith', role: 'UI/UX Designer', time: '1d ago', status: 'Applied'),
    Candidate(id: '3', name: 'Mike Johnson', role: 'Backend Engineer', time: '5d ago', status: 'Screening'),
    Candidate(id: '4', name: 'Emma Davis', role: 'Product Manager', time: '1w ago', status: 'Interview'),
    Candidate(id: '5', name: 'Ali Hassan', role: 'QA Engineer', time: '3d ago', status: 'Interview'),
    Candidate(id: '6', name: 'Mona Zaki', role: 'Marketing Lead', time: '2w ago', status: 'Hired'),
  ];

  final List<String> columns = ['Applied', 'Screening', 'Interview', 'Offer', 'Hired'];

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
                const Text(
                  'Recruitment Pipeline',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Iconsax.add),
                  label: const Text('Post New Job'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: columns.map((col) {
                    final colCandidates = candidates.where((c) => c.status == col).toList();
                    return Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: _buildKanbanColumn(context, col, colCandidates),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKanbanColumn(BuildContext context, String title, List<Candidate> colCandidates) {
    return DragTarget<Candidate>(
      onWillAcceptWithDetails: (details) => details.data.status != title,
      onAcceptWithDetails: (details) {
        setState(() {
          details.data.status = title;
        });
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 300,
          decoration: BoxDecoration(
            color: isHovered 
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.05)
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isHovered 
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
                  : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
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
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('${colCandidates.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: colCandidates.isEmpty
                    ? Center(
                        child: Text(
                          'No candidates',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: colCandidates.length,
                        itemBuilder: (context, index) {
                          final c = colCandidates[index];
                          return Draggable<Candidate>(
                            data: c,
                            feedback: Material(
                              elevation: 8,
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                width: 268,
                                child: _buildCandidateCard(c, isDragging: true),
                              ),
                            ),
                            childWhenDragging: Opacity(
                              opacity: 0.3,
                              child: _buildCandidateCard(c),
                            ),
                            child: _buildCandidateCard(c),
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

  Widget _buildCandidateCard(Candidate c, {bool isDragging = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isDragging ? 8 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      shadowColor: Colors.black.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              c.name,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(c.role, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Iconsax.clock, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(c.time, style: const TextStyle(color: Colors.grey, fontSize: 10)),
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
}
