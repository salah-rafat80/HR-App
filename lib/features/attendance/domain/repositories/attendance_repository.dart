import '../entities/attendance_enums.dart';
import '../entities/attendance_record.dart';
import '../entities/shift_info.dart';

abstract class AttendanceRepository {
  Future<AttendanceRecord> getTodayStatus();
  Future<void> clockIn(String locationLabel, AttendanceStatus mode);
  Future<void> clockOut();
  Future<List<AttendanceRecord>> getHistory();
  Future<ShiftInfo> getShift();
  Future<void> requestOvertime(double hours, String reason);
  Future<void> startBreak();
  Future<void> endBreak();
}
