import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';

class RecruitmentPipelineTab extends StatelessWidget {
  const RecruitmentPipelineTab({super.key});

  @override
  Widget build(BuildContext context) {
    // Read-only fake list of open positions
    final positions = [
      {'title': 'Senior Flutter Engineer', 'applied': 45, 'interview': 12, 'offer': 2, 'hired': 0},
      {'title': 'Product Designer', 'applied': 120, 'interview': 8, 'offer': 1, 'hired': 1},
      {'title': 'QA Automation Lead', 'applied': 30, 'interview': 5, 'offer': 0, 'hired': 0},
    ];

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: positions.length,
      itemBuilder: (context, index) {
        final pos = positions[index];
        return AppCard(
          margin: EdgeInsets.only(bottom: 12.h),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pos['title'] as String, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
                SizedBox(height: 12.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatCol('Applied', pos['applied'] as int),
                    _buildStatCol('Interview', pos['interview'] as int),
                    _buildStatCol('Offer', pos['offer'] as int),
                    _buildStatCol('Hired', pos['hired'] as int),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCol(String label, int value) {
    return Column(
      children: [
        Text(value.toString(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp, color: AppColors.primary)),
        SizedBox(height: 4.h),
        Text(label, style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary)),
      ],
    );
  }
}
