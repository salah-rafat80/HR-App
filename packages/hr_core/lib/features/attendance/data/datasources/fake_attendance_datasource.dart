import '../../domain/entities/attendance_enums.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/overtime_request.dart';
import '../../domain/entities/shift_info.dart';
import '../../domain/repositories/attendance_repository.dart';

/// Fake implementation for isolated tests only.
/// Production DI registers [ApiAttendanceRepositoryImpl] directly.
class FakeAttendanceRepository implements AttendanceRepository {
  AttendanceRecord _todayRecord = AttendanceRecord(
    date: DateTime.now(),
    status: AttendanceStatus.none,
    locationLabel: 'none',
  );
  final List<OvertimeRequest> _overtimeRequests = [];

  @override
  Future<AttendanceRecord> getTodayStatus() async => _todayRecord;

  @override
  Future<GeofenceStatus> preflightGeofence({
    required double lat,
    required double lng,
    required double accuracy,
  }) async =>
      const GeofenceStatus(
        withinRange: true,
        distanceMeters: 50,
        allowedRadiusMeters: 200,
        nearestBranch: 'Test Branch',
      );

  @override
  Future<AttendanceRecord> clockIn({
    required AttendanceStatus mode,
    required double lat,
    required double lng,
    required double accuracy,
  }) async {
    _todayRecord = _todayRecord.copyWith(
      clockInTime: DateTime.now(),
      status: mode,
      locationLabel: 'Test Branch',
    );
    return _todayRecord;
  }

  @override
  Future<void> clockOut() async {
    _todayRecord = _todayRecord.copyWith(clockOutTime: DateTime.now());
  }

  @override
  Future<List<AttendanceRecord>> getHistory() async => const [];

  @override
  Future<ShiftInfo> getShift() async {
    final now = DateTime.now();
    return ShiftInfo(
      name: 'Test Shift',
      startTime: DateTime(now.year, now.month, now.day, 9),
      endTime: DateTime(now.year, now.month, now.day, 17),
    );
  }

  @override
  Future<OvertimeRequest> requestOvertime({
    required DateTime requestedStartAt,
    required DateTime requestedEndAt,
    required String reason,
  }) async {
    final request = OvertimeRequest(
      id: 'test-ot-${DateTime.now().microsecondsSinceEpoch}',
      userId: 'test-user',
      date: DateTime(
        requestedStartAt.year,
        requestedStartAt.month,
        requestedStartAt.day,
      ),
      requestedStartAt: requestedStartAt,
      requestedEndAt: requestedEndAt,
      requestedMinutes: requestedEndAt.difference(requestedStartAt).inMinutes,
      reason: reason,
      status: OvertimeStatus.pendingTeamLead,
      submittedAt: DateTime.now(),
    );
    _overtimeRequests.insert(0, request);
    return request;
  }

  @override
  Future<List<OvertimeRequest>> getMyOvertimeRequests() async =>
      List.unmodifiable(_overtimeRequests);

  @override
  Future<List<OvertimeRequest>> getPendingOvertimeApprovals() async => const [];

  @override
  Future<OvertimeRequest> approveOvertimeAsTeamLead(
    String requestId, {
    String? comment,
  }) =>
      Future.error(UnsupportedError('Fake approval flow is not implemented'));

  @override
  Future<OvertimeRequest> rejectOvertimeAsTeamLead(
    String requestId, {
    String? comment,
  }) =>
      Future.error(UnsupportedError('Fake approval flow is not implemented'));

  @override
  Future<OvertimeRequest> approveOvertimeAsHr(
    String requestId, {
    String? comment,
  }) =>
      Future.error(UnsupportedError('Fake approval flow is not implemented'));

  @override
  Future<OvertimeRequest> rejectOvertimeAsHr(
    String requestId, {
    String? comment,
  }) =>
      Future.error(UnsupportedError('Fake approval flow is not implemented'));

  @override
  Future<OvertimeSession> startOvertimeSession(
    String requestId, {
    required double lat,
    required double lng,
    required double accuracy,
  }) =>
      Future.error(UnsupportedError('Fake session flow is not implemented'));

  @override
  Future<OvertimeSession> endOvertimeSession(
    String sessionId, {
    required double lat,
    required double lng,
    required double accuracy,
  }) =>
      Future.error(UnsupportedError('Fake session flow is not implemented'));

  @override
  Future<void> updateTodayMode(AttendanceStatus mode) async {
    _todayRecord = _todayRecord.copyWith(status: mode);
  }

  @override
  Future<void> startBreak() async {}

  @override
  Future<void> endBreak() async {}
}
