import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../widgets/attendance_clock_card.dart';
import '../widgets/attendance_wfh_break_card.dart';

class AttendanceTodayTab extends StatelessWidget {
  const AttendanceTodayTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          const AttendanceClockCard(),
          SizedBox(height: 16.h),
          // P5 — WFH toggle + Break Tracker (hidden when not clocked in)
          const AttendanceWfhBreakCard(),
        ],
      ),
    );
  }
}
