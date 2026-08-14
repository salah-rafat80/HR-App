import '../../domain/entities/attendance_enums.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/overtime_request.dart';
import '../../domain/entities/shift_info.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../datasources/fake_attendance_datasource.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final AttendanceRepository _delegate;

  AttendanceRepositoryImpl([AttendanceRepository? delegate])
      : _delegate = delegate ?? FakeAttendanceRepository();

  @override
  Future<AttendanceRecord> getTodayStatus() => _delegate.getTodayStatus();

  @override
  Future<GeofenceStatus> preflightGeofence({
    required double lat,
    required double lng,
    required double accuracy,
  }) =>
      _delegate.preflightGeofence(lat: lat, lng: lng, accuracy: accuracy);

  @override
  Future<AttendanceRecord> clockIn({
    required AttendanceStatus mode,
    required double lat,
    required double lng,
    required double accuracy,
  }) =>
      _delegate.clockIn(mode: mode, lat: lat, lng: lng, accuracy: accuracy);

  @override
  Future<void> clockOut() => _delegate.clockOut();

  @override
  Future<List<AttendanceRecord>> getHistory() => _delegate.getHistory();

  @override
  Future<ShiftInfo> getShift() => _delegate.getShift();

  @override
  Future<void> requestOvertime(double hours, String reason) =>
      _delegate.requestOvertime(hours, reason);

  @override
  Future<List<OvertimeRequest>> getOvertimeRequests() =>
      _delegate.getOvertimeRequests();

  @override
  Future<void> updateTodayMode(AttendanceStatus mode) =>
      _delegate.updateTodayMode(mode);

  @override
  Future<void> startBreak() => _delegate.startBreak();

  @override
  Future<void> endBreak() => _delegate.endBreak();
}
