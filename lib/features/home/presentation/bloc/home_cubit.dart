import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'home_state.dart';
import '../../domain/repositories/home_repository.dart';
import '../../../attendance/domain/repositories/attendance_repository.dart';
import '../../../leave/domain/repositories/leave_repository.dart';
import '../../../leave/domain/entities/leave_enums.dart';
import '../../domain/entities/home_entities.dart';
import '../../../attendance/domain/entities/attendance_enums.dart';
import '../../../kpi/domain/repositories/kpi_repository.dart';
import '../../../training/domain/repositories/training_repository.dart';

class HomeCubit extends Cubit<HomeState> {
  final HomeRepository _homeRepository;
  final AttendanceRepository _attendanceRepository;
  final LeaveRepository _leaveRepository;
  final KpiRepository _kpiRepository;
  final TrainingRepository _trainingRepository;

  HomeCubit(this._homeRepository, this._attendanceRepository, this._leaveRepository, this._kpiRepository, this._trainingRepository) : super(HomeInitial());

  Future<void> loadDashboard() async {
    if (!isClosed) { emit(HomeLoading()); }
    try {
      final data = await _homeRepository.getDashboardData();
      var attendance = await _attendanceRepository.getTodayStatus();
      
      final balances = await _leaveRepository.getBalances();
      final totalLeft = balances.fold<int>(0, (sum, b) => sum + b.daysLeft);
      final totalDays = balances.fold<int>(0, (sum, b) => sum + b.daysTotal);

      final requests = await _leaveRepository.getMyRequests();
      final onLeaveToday = requests.any((r) => 
        r.overallStatus == LeaveStatus.approved && 
        r.startDate.isBefore(DateTime.now().add(const Duration(days: 1))) &&
        r.endDate.isAfter(DateTime.now().subtract(const Duration(days: 1)))
      );

      if (onLeaveToday) {
        attendance = attendance.copyWith(status: AttendanceStatus.onLeave, locationLabel: 'on_leave_today_msg'.tr());
      }

      final kpiScore = await _kpiRepository.getOverallQuarterScore();
      final pendingTrainings = await _trainingRepository.getPendingMandatoryCourses();

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

      if (!isClosed) { emit(HomeLoaded(data: updatedData, todayAttendance: attendance)); }
    } catch (e) {
      if (!isClosed) { emit(HomeError(e.toString())); }
    }
  }

  Future<void> refreshAttendance() async {
    if (state is HomeLoaded) {
      try {
        final currentData = (state as HomeLoaded).data;
        var attendance = await _attendanceRepository.getTodayStatus();
        final balances = await _leaveRepository.getBalances();
        final totalLeft = balances.fold<int>(0, (sum, b) => sum + b.daysLeft);
        final totalDays = balances.fold<int>(0, (sum, b) => sum + b.daysTotal);

        final requests = await _leaveRepository.getMyRequests();
        final onLeaveToday = requests.any((r) => 
          r.overallStatus == LeaveStatus.approved && 
          r.startDate.isBefore(DateTime.now().add(const Duration(days: 1))) &&
          r.endDate.isAfter(DateTime.now().subtract(const Duration(days: 1)))
        );

        if (onLeaveToday) {
          attendance = attendance.copyWith(status: AttendanceStatus.onLeave, locationLabel: 'on_leave_today_msg'.tr());
        }

        final kpiScore = await _kpiRepository.getOverallQuarterScore();
        final pendingTrainings = await _trainingRepository.getPendingMandatoryCourses();

        final updatedData = HomeDashboardData(
          employeeName: currentData.employeeName,
          todayDate: currentData.todayDate,
          leaveDaysLeft: totalLeft,
          leaveDaysTotal: totalDays,
          kpiScorePercent: kpiScore,
          announcements: currentData.announcements,
          birthdaysToday: currentData.birthdaysToday,
          upcomingHolidays: currentData.upcomingHolidays,
          pendingMandatoryTrainingCount: pendingTrainings.length,
        );

        if (!isClosed) { emit(HomeLoaded(data: updatedData, todayAttendance: attendance)); }
      } catch (e) {
        // Silent fail on refresh
      }
    }
  }
}
