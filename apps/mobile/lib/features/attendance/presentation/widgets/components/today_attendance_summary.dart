import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hr_core/features/attendance/domain/entities/attendance_record.dart';

class TodayAttendanceSummary extends StatelessWidget {
  final AttendanceRecord todayRec;

  const TodayAttendanceSummary({super.key, required this.todayRec});

  @override
  Widget build(BuildContext context) {
    bool isArabic = false;
    try {
      isArabic = context.locale.languageCode == 'ar';
    } catch (_) {}
    final timeFormat = DateFormat('hh:mm a');
    final inStr = timeFormat.format(todayRec.clockInTime!);
    final outStr = todayRec.clockOutTime != null
        ? timeFormat.format(todayRec.clockOutTime!)
        : (isArabic ? 'جاري العمل...' : 'Working...');

    return Container(
      margin: EdgeInsets.only(top: 24.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text(
                isArabic ? 'توقيت الحضور' : 'Check In Time',
                style: TextStyle(fontSize: 11.sp, color: Colors.white70),
              ),
              SizedBox(height: 4.h),
              Text(
                inStr,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp, color: Colors.white),
              ),
            ],
          ),
          Container(height: 24.h, width: 1, color: Colors.white24),
          Column(
            children: [
              Text(
                isArabic ? 'توقيت الانصراف' : 'Check Out Time',
                style: TextStyle(fontSize: 11.sp, color: Colors.white70),
              ),
              SizedBox(height: 4.h),
              Text(
                outStr,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.sp,
                  color: todayRec.clockOutTime != null ? Colors.white70 : const Color(0xFFFFB74D),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
