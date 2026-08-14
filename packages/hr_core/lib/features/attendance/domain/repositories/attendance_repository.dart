import '../entities/attendance_enums.dart';
import '../entities/attendance_record.dart';
import '../entities/overtime_request.dart';
import '../entities/shift_info.dart';

abstract class AttendanceRepository {
  Future<AttendanceRecord> getTodayStatus();

  Future<GeofenceStatus> preflightGeofence({
    required double lat,
    required double lng,
    required double accuracy,
  });

  Future<AttendanceRecord> clockIn({
    required AttendanceStatus mode,
    required double lat,
    required double lng,
    required double accuracy,
  });

  Future<void> clockOut();
  Future<List<AttendanceRecord>> getHistory();
  Future<ShiftInfo> getShift();

  Future<OvertimeRequest> requestOvertime({
    required DateTime requestedStartAt,
    required DateTime requestedEndAt,
    required String reason,
  });

  Future<List<OvertimeRequest>> getMyOvertimeRequests();
  Future<List<OvertimeRequest>> getPendingOvertimeApprovals();

  Future<OvertimeRequest> approveOvertimeAsTeamLead(
    String requestId, {
    String? comment,
  });

  Future<OvertimeRequest> rejectOvertimeAsTeamLead(
    String requestId, {
    String? comment,
  });

  Future<OvertimeRequest> approveOvertimeAsHr(
    String requestId, {
    String? comment,
  });

  Future<OvertimeRequest> rejectOvertimeAsHr(
    String requestId, {
    String? comment,
  });

  Future<OvertimeSession> startOvertimeSession(
    String requestId, {
    required double lat,
    required double lng,
    required double accuracy,
  });

  Future<OvertimeSession> endOvertimeSession(
    String sessionId, {
    required double lat,
    required double lng,
    required double accuracy,
  });

  Future<void> updateTodayMode(AttendanceStatus mode);
  Future<void> startBreak();
  Future<void> endBreak();
}
