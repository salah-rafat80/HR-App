import 'package:hr_app_demo/core/utils/safe_cubit.dart';
import 'attendance_state.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../../domain/entities/attendance_enums.dart';
import '../../../leave/domain/repositories/leave_repository.dart';
import '../../../leave/domain/entities/leave_enums.dart';
import 'package:easy_localization/easy_localization.dart';

class AttendanceCubit extends SafeCubit<AttendanceState> {
  final AttendanceRepository _repository;
  final LeaveRepository _leaveRepository;

  AttendanceCubit(this._repository, this._leaveRepository) : super(AttendanceInitial());

  Future<void> loadAttendanceData() async {
    if (!isClosed) { emit(AttendanceLoading()); }
    try {
      var today = await _repository.getTodayStatus();
      final history = await _repository.getHistory();
      final shift = await _repository.getShift();

      final requests = await _leaveRepository.getMyRequests();
      final onLeaveToday = requests.any((r) => 
        r.overallStatus == LeaveStatus.approved && 
        r.startDate.isBefore(DateTime.now().add(const Duration(days: 1))) &&
        r.endDate.isAfter(DateTime.now().subtract(const Duration(days: 1)))
      );

      if (onLeaveToday) {
        today = today.copyWith(status: AttendanceStatus.onLeave, locationLabel: 'on_leave_today_msg'.tr());
      }

      if (!isClosed) { emit(AttendanceLoaded(todayStatus: today, history: history, shift: shift)); }
    } catch (e) {
      if (!isClosed) { emit(AttendanceError(e.toString())); }
    }
  }

  Future<void> clockIn(String locationLabel) async {
    if (state is! AttendanceLoaded) return;
    
    // Optimistic UI could be applied here, but let's wait for the "backend" to simulate the flow
    try {
      await _repository.clockIn(locationLabel, AttendanceStatus.present);
      final updatedToday = await _repository.getTodayStatus();
      if (!isClosed) { emit((state as AttendanceLoaded).copyWith(todayStatus: updatedToday)); }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> clockOut() async {
    if (state is! AttendanceLoaded) return;
    
    try {
      await _repository.clockOut();
      final updatedToday = await _repository.getTodayStatus();
      if (!isClosed) { emit((state as AttendanceLoaded).copyWith(todayStatus: updatedToday)); }
    } catch (e) {
      // Handle error
    }
  }
}
