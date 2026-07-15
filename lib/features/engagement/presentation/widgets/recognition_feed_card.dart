import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/engagement_entities.dart';
import '../bloc/engagement_cubit.dart';

class RecognitionFeedCard extends StatelessWidget {
  final List<RecognitionBadge> feed;
  
  const RecognitionFeedCard({super.key, required this.feed});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recognition Feed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                TextButton.icon(
                  onPressed: () => _showGiveRecognitionDialog(context),
                  icon: const Icon(Icons.stars),
                  label: const Text('Give'),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            if (feed.isEmpty)
              const Center(child: Text('No recognitions yet.', style: TextStyle(color: AppColors.textSecondary))),
            ...feed.map((badge) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: const Icon(Icons.workspace_premium, color: AppColors.primary),
              ),
              title: Text('${badge.fromName} recognized ${badge.toName}'),
              subtitle: Text('Badge: ${badge.badgeType}\n"${badge.message}"'),
              trailing: Text('+${badge.pointsAwarded} pts', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              isThreeLine: true,
            )),
          ],
        ),
      ),
    );
  }

  void _showGiveRecognitionDialog(BuildContext parentContext) {
    final toCtrl = TextEditingController();
    final badgeCtrl = TextEditingController();
    final msgCtrl = TextEditingController();

    showDialog(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Give Recognition'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: toCtrl, decoration: const InputDecoration(labelText: 'Colleague Name')),
            SizedBox(height: 12.h),
            TextField(controller: badgeCtrl, decoration: const InputDecoration(labelText: 'Badge Type (e.g. Team Player)')),
            SizedBox(height: 12.h),
            TextField(controller: msgCtrl, decoration: const InputDecoration(labelText: 'Message')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (toCtrl.text.isNotEmpty && badgeCtrl.text.isNotEmpty && msgCtrl.text.isNotEmpty) {
                parentContext.read<EngagementCubit>().giveRecognition(toCtrl.text, badgeCtrl.text, msgCtrl.text);
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Give'),
          ),
        ],
      ),
    );
  }
}
