import '../entities/attendance_enums.dart';
import '../entities/attendance_record.dart';
import '../entities/overtime_request.dart';
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

  /// Submit a new overtime request and return its persisted form.
  Future<void> requestOvertime(double hours, String reason);

  /// Fetch all overtime requests submitted by the current user.
  Future<List<OvertimeRequest>> getOvertimeRequests();

  /// Patch only the mode/status of today's existing record.
  /// Used by WFH toggle — does NOT create a new clock-in record.
  Future<void> updateTodayMode(AttendanceStatus mode);

  Future<void> startBreak();
  Future<void> endBreak();
}
