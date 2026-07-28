import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hr_app_demo/core/theme/app_colors.dart';
import 'package:hr_app_demo/core/widgets/app_card.dart';
import '../bloc/attendance_cubit.dart';
import '../bloc/attendance_state.dart';

/// Shows WFH toggle and Break Tracker only when the user is clocked in.
/// WFH uses PATCH /attendance/today/mode — does NOT create a new clockIn record.
class AttendanceWfhBreakCard extends StatefulWidget {
  const AttendanceWfhBreakCard({super.key});

  @override
  State<AttendanceWfhBreakCard> createState() => _AttendanceWfhBreakCardState();
}

class _AttendanceWfhBreakCardState extends State<AttendanceWfhBreakCard> {
  Timer? _breakTimer;
  Duration _elapsed = Duration.zero;

  @override
  void dispose() {
    _breakTimer?.cancel();
    super.dispose();
  }

  void _startBreakTimer(DateTime startTime) {
    _breakTimer?.cancel();
    _breakTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _elapsed = DateTime.now().difference(startTime);
        });
      }
    });
  }

  void _stopBreakTimer() {
    _breakTimer?.cancel();
    setState(() => _elapsed = Duration.zero);
  }

  String _formatElapsed(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AttendanceCubit, AttendanceState>(
      listenWhen: (previous, current) {
        if (previous is AttendanceLoaded && current is AttendanceLoaded) {
          // Break just started
          if (!previous.isOnBreak && current.isOnBreak && current.breakStartTime != null) {
            return true;
          }
          // Break just ended
          if (previous.isOnBreak && !current.isOnBreak) return true;
        }
        return false;
      },
      listener: (context, state) {
        if (state is AttendanceLoaded) {
          if (state.isOnBreak && state.breakStartTime != null) {
            _startBreakTimer(state.breakStartTime!);
          } else {
            _stopBreakTimer();
          }
        }
      },
      builder: (context, state) {
        if (state is! AttendanceLoaded) return const SizedBox.shrink();

        final isClockedIn = state.todayStatus.clockInTime != null &&
            state.todayStatus.clockOutTime == null;

        // Card is hidden until the user is clocked in
        if (!isClockedIn) return const SizedBox.shrink();

        final isArabic = context.locale.languageCode == 'ar';

        return AppCard(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── WFH Toggle ─────────────────────────────────────────────────
                Row(
                  children: [
                    Icon(Icons.home_work_outlined,
                        color: state.isWfh ? AppColors.primary : AppColors.textSecondary,
                        size: 20.sp),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        isArabic ? 'العمل من المنزل' : 'Work From Home',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: state.isWfh ? AppColors.primary : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    // Status chip
                    if (state.isWfh)
                      Container(
                        margin: EdgeInsets.only(right: 8.w),
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Text(
                          isArabic ? 'نشط' : 'Active',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    Switch(
                      value: state.isWfh,
                      activeColor: AppColors.primary,
                      onChanged: (_) => context.read<AttendanceCubit>().toggleWfh(),
                    ),
                  ],
                ),

                Divider(height: 24.h, thickness: 0.8),

                // ── Break Tracker ──────────────────────────────────────────────
                Row(
                  children: [
                    Icon(Icons.free_breakfast_outlined,
                        color: state.isOnBreak ? AppColors.warning : AppColors.textSecondary,
                        size: 20.sp),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isArabic ? 'استراحة' : 'Break',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: state.isOnBreak
                                  ? AppColors.warning
                                  : AppColors.textPrimary,
                            ),
                          ),
                          if (state.isOnBreak)
                            Text(
                              _formatElapsed(_elapsed),
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.warning,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (state.isOnBreak) {
                          context.read<AttendanceCubit>().endBreak();
                        } else {
                          context.read<AttendanceCubit>().startBreak();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            state.isOnBreak ? AppColors.error : AppColors.warning,
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 10.h),
                      ),
                      child: Text(
                        state.isOnBreak
                            ? (isArabic ? 'إنهاء الاستراحة' : 'End Break')
                            : (isArabic ? 'بدء استراحة' : 'Start Break'),
                        style: TextStyle(fontSize: 12.sp, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
