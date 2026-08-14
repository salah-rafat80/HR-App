import '../entities/attendance_enums.dart';
import '../entities/attendance_record.dart';
import '../entities/overtime_request.dart';
import '../entities/shift_info.dart';

/// Abstract contract for all attendance operations.
///
/// locationLabel is intentionally absent from all write methods —
/// the backend derives and persists the branch label from its own geofence
/// result only.
abstract class AttendanceRepository {
  Future<AttendanceRecord> getTodayStatus();

  /// Geofence preflight — calls GET /attendance/geofence-status.
  /// [lat], [lng], and [accuracy] are all required.
  /// Returns the server's authoritative geofence result.
  Future<GeofenceStatus> preflightGeofence({
    required double lat,
    required double lng,
    required double accuracy,
  });

  /// Sends a single clock-in request after a successful biometric.
  /// Returns the persisted [AttendanceRecord] — the sole source of
  /// truth for the UI success confirmation.
  Future<AttendanceRecord> clockIn({
    required AttendanceStatus mode,
    required double lat,
    required double lng,
    required double accuracy,
  });

  Future<void> clockOut();
  Future<List<AttendanceRecord>> getHistory();
  Future<ShiftInfo> getShift();

  /// Submit a new overtime request.
  Future<void> requestOvertime(double hours, String reason);

  /// Fetch all overtime requests submitted by the current user.
  Future<List<OvertimeRequest>> getOvertimeRequests();

  /// Patch only the mode/status of today's existing record.
  /// Used by WFH toggle — does NOT create a new clock-in record.
  Future<void> updateTodayMode(AttendanceStatus mode);

  Future<void> startBreak();
  Future<void> endBreak();
}
