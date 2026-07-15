import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/engagement_entities.dart';
import '../bloc/engagement_cubit.dart';

class RewardsCard extends StatelessWidget {
  final List<RewardItem> rewards;
  final int myPoints;
  
  const RewardsCard({super.key, required this.rewards, required this.myPoints});

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
                const Text('My Rewards', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('$myPoints pts', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            ...rewards.map((reward) {
              final canAfford = myPoints >= reward.pointsCost;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.card_giftcard, color: AppColors.primary),
                title: Text(reward.name),
                subtitle: Text('${reward.pointsCost} points'),
                trailing: ElevatedButton(
                  onPressed: canAfford ? () {
                    context.read<EngagementCubit>().redeemReward(reward.id);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reward redeemed!')));
                  } : null,
                  child: const Text('Redeem'),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
