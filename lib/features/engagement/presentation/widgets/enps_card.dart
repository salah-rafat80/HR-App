import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/engagement_entities.dart';
import '../bloc/engagement_cubit.dart';

class EnpsCard extends StatelessWidget {
  final EnpsPrompt enps;
  
  const EnpsCard({super.key, required this.enps});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('eNPS Survey', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 12.h),
            Text(enps.questionText),
            SizedBox(height: 16.h),
            enps.answer != null
                ? const Center(child: Text('Thank you for your score!', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)))
                : Wrap(
                    spacing: 4.w,
                    runSpacing: 4.h,
                    alignment: WrapAlignment.center,
                    children: List.generate(11, (index) {
                      return InkWell(
                        onTap: () => context.read<EngagementCubit>().submitEnpsScore(index),
                        child: Container(
                          width: 28.w,
                          height: 28.w,
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.primary),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          alignment: Alignment.center,
                          child: Text('$index', style: const TextStyle(color: AppColors.primary)),
                        ),
                      );
                    }),
                  ),
          ],
        ),
      ),
    );
  }
}
