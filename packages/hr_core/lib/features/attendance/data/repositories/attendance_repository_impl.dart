import '../../domain/entities/attendance_enums.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/overtime_request.dart';
import '../../domain/entities/shift_info.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../datasources/fake_attendance_datasource.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final FakeAttendanceDataSource _dataSource;

  AttendanceRepositoryImpl(this._dataSource);

  @override
  Future<void> clockIn({
    required String locationLabel,
    required AttendanceStatus mode,
    double? lat,
    double? lng,
    double? accuracy,
  }) {
    return _dataSource.clockIn(
      locationLabel: locationLabel,
      mode: mode,
      lat: lat,
      lng: lng,
      accuracy: accuracy,
    );
  }

  @override
  Future<GeofenceStatus> getGeofenceStatus({required double lat, required double lng}) {
    return _dataSource.getGeofenceStatus(lat: lat, lng: lng);
  }

  @override
  Future<void> clockOut() {
    return _dataSource.clockOut();
  }

  @override
  Future<void> endBreak() {
    return _dataSource.endBreak();
  }

  @override
  Future<List<AttendanceRecord>> getHistory() {
    return _dataSource.getHistory();
  }

  @override
  Future<ShiftInfo> getShift() {
    return _dataSource.getShift();
  }

  @override
  Future<AttendanceRecord> getTodayStatus() {
    return _dataSource.getTodayStatus();
  }

  @override
  Future<void> requestOvertime(double hours, String reason) {
    return _dataSource.requestOvertime(hours, reason);
  }

  @override
  Future<List<OvertimeRequest>> getOvertimeRequests() {
    return _dataSource.getOvertimeRequests();
  }

  @override
  Future<void> updateTodayMode(AttendanceStatus mode) {
    return _dataSource.updateTodayMode(mode);
  }

  @override
  Future<void> startBreak() {
    return _dataSource.startBreak();
  }
}
