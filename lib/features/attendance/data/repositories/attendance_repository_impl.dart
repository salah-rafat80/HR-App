import '../../domain/entities/attendance_enums.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/shift_info.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../datasources/fake_attendance_datasource.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final FakeAttendanceDataSource _dataSource;

  AttendanceRepositoryImpl(this._dataSource);

  @override
  Future<void> clockIn(String locationLabel, AttendanceStatus mode) {
    return _dataSource.clockIn(locationLabel, mode);
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
  Future<void> startBreak() {
    return _dataSource.startBreak();
  }
}
