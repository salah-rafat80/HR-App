import 'package:flutter/foundation.dart';
import 'package:hr_app_demo/core/utils/safe_cubit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'home_state.dart';
import 'package:hr_core/features/home/domain/repositories/home_repository.dart';
import 'package:hr_core/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:hr_core/features/leave/domain/repositories/leave_repository.dart';
import 'package:hr_core/features/leave/domain/entities/leave_enums.dart';
import 'package:hr_core/features/home/domain/entities/home_entities.dart';
import 'package:hr_core/features/attendance/domain/entities/attendance_enums.dart';
import 'package:hr_core/features/attendance/domain/entities/attendance_record.dart';
import 'package:hr_core/features/kpi/domain/repositories/kpi_repository.dart';
import 'package:hr_core/features/training/domain/repositories/training_repository.dart';

class _HomeDashboardPayload {
  final HomeDashboardData data;
  final AttendanceRecord todayAttendance;

  const _HomeDashboardPayload({
    required this.data,
    required this.todayAttendance,
  });
}

class HomeCubit extends SafeCubit<HomeState> {
  final HomeRepository _homeRepository;
  final AttendanceRepository _attendanceRepository;
  final LeaveRepository _leaveRepository;
  final KpiRepository _kpiRepository;
  final TrainingRepository _trainingRepository;

  HomeCubit(
    this._homeRepository,
    this._attendanceRepository,
    this._leaveRepository,
    this._kpiRepository,
    this._trainingRepository,
  ) : super(HomeInitial());

  Future<void> loadDashboard() async {
    if (!isClosed) { emit(HomeLoading()); }
    try {
      final payload = await _fetchDashboardPayload();
      if (!isClosed) {
        emit(HomeLoaded(data: payload.data, todayAttendance: payload.todayAttendance));
      }
    } catch (e, stackTrace) {
      debugPrint('HomeCubit loadDashboard error: $e\n$stackTrace');
      if (!isClosed) {
        emit(HomeError('dashboard_load_failed'.tr()));
      }
    }
  }

  Future<void> refreshAttendance() async {
    if (state is HomeLoaded) {
      try {
        final payload = await _fetchDashboardPayload();
        if (!isClosed) {
          emit(HomeLoaded(data: payload.data, todayAttendance: payload.todayAttendance));
        }
      } catch (e, stackTrace) {
        debugPrint('HomeCubit refreshAttendance silent error: $e\n$stackTrace');
      }
    }
  }


  Future<_HomeDashboardPayload> _fetchDashboardPayload() async {
    final dataFuture = _homeRepository.getDashboardData();
    final todayAttendanceFuture = _attendanceRepository.getTodayStatus();
    final balancesFuture = _leaveRepository.getBalances();
    final requestsFuture = _leaveRepository.getMyRequests();
    final kpiScoreFuture = _kpiRepository.getOverallQuarterScore();
    final pendingTrainingsFuture = _trainingRepository.getPendingMandatoryCourses();

    final data = await dataFuture;
    var attendance = await todayAttendanceFuture;
    final balances = await balancesFuture;
    final totalLeft = balances.fold<int>(0, (sum, b) => sum + b.daysLeft);
    final totalDays = balances.fold<int>(0, (sum, b) => sum + b.daysTotal);

    final requests = await requestsFuture;

    // Calendar day boundary matching for today's leave status (F-002)
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final onLeaveToday = requests.any((r) => 
      r.overallStatus == LeaveStatus.approved && 
      !r.startDate.isAfter(todayEnd) &&
      !r.endDate.isBefore(todayStart)
    );

    if (onLeaveToday) {
      attendance = attendance.copyWith(
        status: AttendanceStatus.onLeave,
        locationLabel: 'on_leave_today_msg'.tr(),
      );
    }

    final kpiScore = await kpiScoreFuture;
    final pendingTrainings = await pendingTrainingsFuture;

    final updatedData = HomeDashboardData(
      employeeName: data.employeeName,
      todayDate: data.todayDate,
      leaveDaysLeft: totalLeft,
      leaveDaysTotal: totalDays,
      kpiScorePercent: kpiScore,
      announcements: data.announcements,
      birthdaysToday: data.birthdaysToday,
      upcomingHolidays: data.upcomingHolidays,
      pendingMandatoryTrainingCount: pendingTrainings.length,
    );

    return _HomeDashboardPayload(
      data: updatedData,
      todayAttendance: attendance,
    );
  }
}

