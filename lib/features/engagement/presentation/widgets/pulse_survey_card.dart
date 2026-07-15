import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/engagement_entities.dart';
import '../bloc/engagement_cubit.dart';

class PulseSurveyCard extends StatelessWidget {
  final PulseSurveyPrompt pulse;
  
  const PulseSurveyCard({super.key, required this.pulse});

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
                const Text('Pulse Survey', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(pulse.weekLabel, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
            SizedBox(height: 12.h),
            Text(pulse.questionText),
            SizedBox(height: 16.h),
            pulse.answer != null
                ? const Center(child: Text('Thanks for your feedback!', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(5, (index) {
                      final rating = index + 1;
                      return IconButton(
                        icon: Icon(Icons.star_border, color: AppColors.primary, size: 30.sp),
                        onPressed: () {
                          context.read<EngagementCubit>().submitPulseAnswer(rating);
                        },
                      );
                    }),
                  ),
          ],
        ),
      ),
    );
  }
}
