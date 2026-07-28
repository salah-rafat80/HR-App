import '../../domain/entities/attendance_enums.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/overtime_request.dart';
import '../../domain/entities/shift_info.dart';

class FakeAttendanceDataSource {
  AttendanceRecord _todayRecord = AttendanceRecord(
    date: DateTime.now(),
    status: AttendanceStatus.none,
    locationLabel: 'none',
  );

  final List<AttendanceRecord> _history = List.generate(
    14,
    (index) => AttendanceRecord(
      date: DateTime.now().subtract(Duration(days: index + 1)),
      clockInTime: DateTime.now().subtract(Duration(days: index + 1, hours: 8)),
      clockOutTime: DateTime.now().subtract(Duration(days: index + 1, hours: 0)),
      status: index % 5 == 0 ? AttendanceStatus.late : AttendanceStatus.present,
      locationLabel: 'Main Office',
    ),
  );

  final List<OvertimeRequest> _overtimeRequests = [
    OvertimeRequest(
      id: 'ot-001',
      hours: 2.0,
      reason: 'Project deadline',
      status: OvertimeStatus.approved,
      submittedAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    OvertimeRequest(
      id: 'ot-002',
      hours: 1.5,
      reason: 'Client call extension',
      status: OvertimeStatus.pending,
      submittedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  final ShiftInfo _shift = ShiftInfo(
    name: 'Morning Shift',
    startTime: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 9, 0),
    endTime: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 17, 0),
  );

  Future<AttendanceRecord> getTodayStatus() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return _todayRecord;
  }

  Future<void> clockIn({
    required String locationLabel,
    required AttendanceStatus mode,
    double? lat,
    double? lng,
    double? accuracy,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    _todayRecord = _todayRecord.copyWith(
      clockInTime: DateTime.now(),
      status: mode,
      locationLabel: locationLabel,
    );
  }

  Future<GeofenceStatus> getGeofenceStatus({required double lat, required double lng}) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return const GeofenceStatus(withinRange: true, distanceMeters: 50, allowedRadiusMeters: 200);
  }

  Future<void> clockOut() async {
    await Future.delayed(const Duration(milliseconds: 800));
    _todayRecord = _todayRecord.copyWith(clockOutTime: DateTime.now());
  }

  Future<List<AttendanceRecord>> getHistory() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return _history;
  }

  Future<ShiftInfo> getShift() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _shift;
  }

  Future<void> requestOvertime(double hours, String reason) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    _overtimeRequests.insert(
      0,
      OvertimeRequest(
        id: 'ot-${DateTime.now().millisecondsSinceEpoch}',
        hours: hours,
        reason: reason,
        status: OvertimeStatus.pending,
        submittedAt: DateTime.now(),
      ),
    );
  }

  Future<List<OvertimeRequest>> getOvertimeRequests() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return List.from(_overtimeRequests);
  }

  /// Patches only the mode/status of today's existing record.
  /// Does NOT create a new clock-in record — used by WFH toggle.
  Future<void> updateTodayMode(AttendanceStatus mode) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _todayRecord = _todayRecord.copyWith(status: mode);
  }

  Future<void> startBreak() async {
    await Future.delayed(const Duration(milliseconds: 400));
  }

  Future<void> endBreak() async {
    await Future.delayed(const Duration(milliseconds: 400));
  }
}
