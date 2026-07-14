import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/home_entities.dart';

class HomeHolidaysSection extends StatelessWidget {
  final List<Holiday> holidays;

  const HomeHolidaysSection({super.key, required this.holidays});

  @override
  Widget build(BuildContext context) {
    if (holidays.isEmpty) return const SizedBox.shrink();
    final df = DateFormat('dd MMM', context.locale.languageCode);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('upcoming_holidays'.tr(), style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 8.h),
          ...holidays.map((h) => Card(
            child: ListTile(
              leading: const Icon(Icons.beach_access, color: AppColors.accent),
              title: Text(h.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
              trailing: Text(df.format(h.date), style: TextStyle(fontSize: 12.sp, color: AppColors.textPrimary)),
            ),
          )),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }
}
