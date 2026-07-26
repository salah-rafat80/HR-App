import 'package:hr_app_demo/core/utils/safe_cubit.dart';
import 'attendance_state.dart';
import 'package:hr_core/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:hr_core/features/attendance/domain/entities/attendance_enums.dart';

import 'package:socket_io_client/socket_io_client.dart' as IO;

class AttendanceCubit extends SafeCubit<AttendanceState> {
  final AttendanceRepository _repository;
  final IO.Socket _socket;

  AttendanceCubit(this._repository, this._socket) : super(AttendanceInitial()) {
    _socket.on('entity.updated', (data) {
      if (data['type'] == 'AttendanceRecord') {
        loadAttendanceData();
      }
    });
  }

  Future<void> loadAttendanceData() async {
    if (!isClosed) { emit(AttendanceLoading()); }
    try {
      var today = await _repository.getTodayStatus();
      final history = await _repository.getHistory();
      final shift = await _repository.getShift();

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
