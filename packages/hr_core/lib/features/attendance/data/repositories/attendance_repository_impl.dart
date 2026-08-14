import '../../domain/entities/attendance_enums.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/overtime_request.dart';
import '../../domain/entities/shift_info.dart';
import '../../domain/repositories/attendance_repository.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final AttendanceRepository _delegate;

  AttendanceRepositoryImpl(this._delegate);

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
  Future<OvertimeRequest> requestOvertime({
    required DateTime requestedStartAt,
    required DateTime requestedEndAt,
    required String reason,
  }) =>
      _delegate.requestOvertime(
        requestedStartAt: requestedStartAt,
        requestedEndAt: requestedEndAt,
        reason: reason,
      );

  @override
  Future<List<OvertimeRequest>> getMyOvertimeRequests() =>
      _delegate.getMyOvertimeRequests();

  @override
  Future<List<OvertimeRequest>> getPendingOvertimeApprovals() =>
      _delegate.getPendingOvertimeApprovals();

  @override
  Future<OvertimeRequest> approveOvertimeAsTeamLead(
    String requestId, {
    String? comment,
  }) =>
      _delegate.approveOvertimeAsTeamLead(requestId, comment: comment);

  @override
  Future<OvertimeRequest> rejectOvertimeAsTeamLead(
    String requestId, {
    String? comment,
  }) =>
      _delegate.rejectOvertimeAsTeamLead(requestId, comment: comment);

  @override
  Future<OvertimeRequest> approveOvertimeAsHr(
    String requestId, {
    String? comment,
  }) =>
      _delegate.approveOvertimeAsHr(requestId, comment: comment);

  @override
  Future<OvertimeRequest> rejectOvertimeAsHr(
    String requestId, {
    String? comment,
  }) =>
      _delegate.rejectOvertimeAsHr(requestId, comment: comment);

  @override
  Future<OvertimeSession> startOvertimeSession(
    String requestId, {
    required double lat,
    required double lng,
    required double accuracy,
  }) =>
      _delegate.startOvertimeSession(
        requestId,
        lat: lat,
        lng: lng,
        accuracy: accuracy,
      );

  @override
  Future<OvertimeSession> endOvertimeSession(
    String sessionId, {
    required double lat,
    required double lng,
    required double accuracy,
  }) =>
      _delegate.endOvertimeSession(
        sessionId,
        lat: lat,
        lng: lng,
        accuracy: accuracy,
      );

  @override
  Future<void> updateTodayMode(AttendanceStatus mode) =>
      _delegate.updateTodayMode(mode);

  @override
  Future<void> startBreak() => _delegate.startBreak();

  @override
  Future<void> endBreak() => _delegate.endBreak();
}
