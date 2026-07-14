import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../domain/entities/home_entities.dart';

class HomeBirthdaysSection extends StatelessWidget {
  final List<Colleague> birthdays;

  const HomeBirthdaysSection({super.key, required this.birthdays});

  @override
  Widget build(BuildContext context) {
    if (birthdays.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('birthdays'.tr(), style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 8.h),
          SizedBox(
            height: 100.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: birthdays.length,
              itemBuilder: (context, index) {
                final b = birthdays[index];
                return Padding(
                  padding: EdgeInsets.only(right: 12.w),
                  child: Column(
                    children: [
                      const CircleAvatar(radius: 24, child: Icon(Icons.cake)),
                      SizedBox(height: 4.h),
                      Text(b.name, style: TextStyle(fontSize: 12.sp)),
                    ],
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
