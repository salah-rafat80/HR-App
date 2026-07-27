import '../entities/attendance_enums.dart';
import '../entities/attendance_record.dart';
import '../entities/shift_info.dart';

abstract class AttendanceRepository {
  Future<AttendanceRecord> getTodayStatus();
  Future<GeofenceStatus> getGeofenceStatus({required double lat, required double lng});
  Future<void> clockIn({
    required String locationLabel,
    required AttendanceStatus mode,
    double? lat,
    double? lng,
    double? accuracy,
  });
  Future<void> clockOut();
  Future<List<AttendanceRecord>> getHistory();
  Future<ShiftInfo> getShift();
  Future<void> requestOvertime(double hours, String reason);
  Future<void> startBreak();
  Future<void> endBreak();
}
