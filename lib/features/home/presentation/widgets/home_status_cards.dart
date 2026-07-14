import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../attendance/domain/entities/attendance_enums.dart';

class HomeStatusCards extends StatelessWidget {
  final int leaveLeft;
  final int leaveTotal;
  final double kpiScore;
  final AttendanceStatus status;

  const HomeStatusCards({
    super.key, required this.leaveLeft, required this.leaveTotal, required this.kpiScore, required this.status,
  });

  String _statusToString(AttendanceStatus s) {
    switch (s) {
      case AttendanceStatus.present: return 'present'.tr();
      case AttendanceStatus.absent: return 'absent'.tr();
      case AttendanceStatus.late: return 'late'.tr();
      case AttendanceStatus.workFromHome: return 'wfh'.tr();
      case AttendanceStatus.onBusinessTrip: return 'on_trip'.tr();
      case AttendanceStatus.onLeave: return 'on_leave'.tr();
      case AttendanceStatus.none: return 'none'.tr();
    }
  }

  Color _statusToColor(AttendanceStatus s) {
    switch (s) {
      case AttendanceStatus.present: return AppColors.success;
      case AttendanceStatus.absent: return AppColors.error;
      case AttendanceStatus.late: return AppColors.warning;
      case AttendanceStatus.workFromHome: return AppColors.secondary;
      default: return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: Row(
        children: [
          Expanded(child: _StatusCard(title: 'status_today'.tr(), value: _statusToString(status), color: _statusToColor(status))),
          SizedBox(width: 12.w),
          Expanded(child: _StatusCard(title: 'leave_balance'.tr(), value: '$leaveLeft / $leaveTotal', color: AppColors.primary)),
          SizedBox(width: 12.w),
          Expanded(child: _StatusCard(title: 'kpi_score'.tr(), value: '${(kpiScore * 100).toInt()}%', color: AppColors.accent)),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatusCard({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary)),
          SizedBox(height: 8.h),
          Text(value, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
