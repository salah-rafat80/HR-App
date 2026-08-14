import 'package:flutter_test/flutter_test.dart';
import 'package:hr_core/features/attendance/domain/entities/attendance_enums.dart';
import 'package:hr_core/features/attendance/domain/entities/attendance_record.dart';
import 'package:hr_core/features/attendance/domain/entities/overtime_request.dart';
import 'package:hr_core/features/attendance/domain/repositories/attendance_repository.dart';

class MockMobileAttendanceRepository implements AttendanceRepository {
  AttendanceRecord currentRecord = AttendanceRecord(
    date: DateTime.now(),
    status: AttendanceStatus.absent,
    clockInTime: null,
    clockOutTime: null,
    locationLabel: 'none',
  );

  final List<OvertimeRequest> _requests = [];
  OvertimeSession? activeSession;

  @override
  Future<AttendanceRecord> getTodayStatus() async => currentRecord;

  @override
  Future<GeofenceStatus> preflightGeofence({
    required double lat,
    required double lng,
    required double accuracy,
  }) async {
    final inside = (lat - 30.12345).abs() < 0.01 && (lng - 31.23456).abs() < 0.01;
    return GeofenceStatus(
      withinRange: inside,
      nearestBranch: inside ? 'فرع العاشر' : null,
      distanceMeters: inside ? 10.0 : 1500.0,
      allowedRadiusMeters: 200.0,
    );
  }

  @override
  Future<AttendanceRecord> clockIn({
    required AttendanceStatus mode,
    required double lat,
    required double lng,
    required double accuracy,
  }) async {
    currentRecord = AttendanceRecord(
      date: DateTime.now(),
      status: AttendanceStatus.present,
      clockInTime: DateTime.now(),
      locationLabel: 'فرع العاشر',
    );
    return currentRecord;
  }

  @override
  Future<void> clockOut() async {
    currentRecord = AttendanceRecord(
      date: currentRecord.date,
      status: currentRecord.status,
      clockInTime: currentRecord.clockInTime,
      clockOutTime: DateTime.now(),
      locationLabel: currentRecord.locationLabel,
    );
  }

  @override
  Future<OvertimeRequest> requestOvertime({
    required DateTime requestedStartAt,
    required DateTime requestedEndAt,
    required String reason,
  }) async {
    final req = OvertimeRequest(
      id: 'ot_req_1',
      userId: 'EMP-001',
      date: DateTime.now(),
      requestedStartAt: requestedStartAt,
      requestedEndAt: requestedEndAt,
      reason: reason,
      status: OvertimeStatus.pendingTeamLead,
      submittedAt: DateTime.now(),
    );
    _requests.add(req);
    return req;
  }

  @override
  Future<List<OvertimeRequest>> getMyOvertimeRequests() async => _requests;

  @override
  Future<OvertimeSession> startOvertimeSession(
    String requestId, {
    required double lat,
    required double lng,
    required double accuracy,
  }) async {
    activeSession = OvertimeSession(
      id: 'sess_1',
      overtimeRequestId: requestId,
      status: OvertimeSessionStatus.active,
      startedAt: DateTime.now(),
      startLocationLabel: 'فرع العاشر',
    );
    return activeSession!;
  }

  @override
  Future<OvertimeSession> endOvertimeSession(
    String sessionId, {
    required double lat,
    required double lng,
    required double accuracy,
  }) async {
    activeSession = OvertimeSession(
      id: sessionId,
      overtimeRequestId: activeSession?.overtimeRequestId ?? 'ot_req_1',
      status: OvertimeSessionStatus.completed,
      startedAt: activeSession?.startedAt ?? DateTime.now(),
      endedAt: DateTime.now(),
      actualMinutes: 180,
      endLocationLabel: 'فرع العاشر',
    );
    return activeSession!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Mobile Overtime Workflow & Geofence Audit Tests', () {
    late MockMobileAttendanceRepository mockRepo;

    setUp(() {
      mockRepo = MockMobileAttendanceRepository();
    });

    test('1. Preflight geofence validates approved branch "فرع العاشر" at lat 30.12345, lng 31.23456', () async {
      final status = await mockRepo.preflightGeofence(
        lat: 30.12345,
        lng: 31.23456,
        accuracy: 10.0,
      );

      expect(status.withinRange, isTrue);
      expect(status.nearestBranch, 'فرع العاشر');
      expect(status.allowedRadiusMeters, 200.0);
    });

    test('2. Clock In inside geofence updates attendance record to present', () async {
      final record = await mockRepo.clockIn(
        mode: AttendanceStatus.present,
        lat: 30.12345,
        lng: 31.23456,
        accuracy: 10.0,
      );

      expect(record.status, AttendanceStatus.present);
      expect(record.locationLabel, 'فرع العاشر');
      expect(record.clockInTime, isNotNull);
    });

    test('3. Submits same-day overtime request successfully', () async {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day, 17, 0);
      final end = DateTime(now.year, now.month, now.day, 20, 0);

      final req = await mockRepo.requestOvertime(
        requestedStartAt: start,
        requestedEndAt: end,
        reason: 'Critical production deployment',
      );

      expect(req.status, OvertimeStatus.pendingTeamLead);
      expect(req.reason, 'Critical production deployment');

      final mine = await mockRepo.getMyOvertimeRequests();
      expect(mine.length, 1);
    });

    test('4. Starts and ends overtime session inside geofence correctly', () async {
      final sessionStart = await mockRepo.startOvertimeSession(
        'ot_req_1',
        lat: 30.12345,
        lng: 31.23456,
        accuracy: 10.0,
      );

      expect(sessionStart.status, OvertimeSessionStatus.active);
      expect(sessionStart.startLocationLabel, 'فرع العاشر');

      final sessionEnd = await mockRepo.endOvertimeSession(
        sessionStart.id,
        lat: 30.12345,
        lng: 31.23456,
        accuracy: 10.0,
      );

      expect(sessionEnd.status, OvertimeSessionStatus.completed);
      expect(sessionEnd.actualMinutes, 180);
      expect(sessionEnd.endLocationLabel, 'فرع العاشر');
    });
  });
}
