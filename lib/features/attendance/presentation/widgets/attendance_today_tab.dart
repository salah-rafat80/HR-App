import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../widgets/attendance_clock_card.dart';

class AttendanceTodayTab extends StatelessWidget {
  const AttendanceTodayTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          const AttendanceClockCard(),
          SizedBox(height: 24.h),
          // We can add WFH toggle and Break Tracker here later, 
          // keeping under 50 lines per widget rule.
        ],
      ),
    );
  }
}
