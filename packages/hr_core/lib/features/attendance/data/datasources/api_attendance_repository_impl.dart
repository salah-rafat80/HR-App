import 'package:dio/dio.dart';
import '../../domain/entities/attendance_enums.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/overtime_request.dart';
import '../../domain/entities/shift_info.dart';
import '../../domain/repositories/attendance_repository.dart';

class ApiAttendanceRepositoryImpl implements AttendanceRepository {
  final Dio dio;

  ApiAttendanceRepositoryImpl({required this.dio});

  @override
  Future<AttendanceRecord> getTodayStatus() async {
    try {
      final response = await dio.get('/attendance/today');
      if (response.data == null || response.data is! Map) {
        return AttendanceRecord(
          date: DateTime.now(),
          status: AttendanceStatus.none,
          locationLabel: 'none',
        );
      }
      return AttendanceRecord.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      return AttendanceRecord(
        date: DateTime.now(),
        status: AttendanceStatus.none,
        locationLabel: 'none',
      );
    }
  }

  /// Geofence preflight — GET /attendance/geofence-status
  /// All three parameters are required; the backend rejects missing/invalid ones.
  @override
  Future<GeofenceStatus> preflightGeofence({
    required double lat,
    required double lng,
    required double accuracy,
  }) async {
    final response = await dio.get(
      '/attendance/geofence-status',
      queryParameters: {
        'lat': lat,
        'lng': lng,
        'accuracy': accuracy,
      },
    );
    if (response.data == null || response.data is! Map) {
      return const GeofenceStatus(
        withinRange: false,
        distanceMeters: 0.0,
        allowedRadiusMeters: 200.0,
        nearestBranch: null,
      );
    }
    final data = response.data as Map<String, dynamic>;
    return GeofenceStatus(
      withinRange: (data['withinRange'] as bool?) ?? false,
      distanceMeters: (data['distanceMeters'] as num?)?.toDouble() ?? 0.0,
      allowedRadiusMeters:
          (data['allowedRadiusMeters'] as num?)?.toDouble() ?? 200.0,
      nearestBranch: data['nearestBranch'] as String?,
    );
  }

  /// Clock-in — POST /attendance/clock-in
  /// Returns the persisted AttendanceRecord from the backend response.
  /// locationLabel is never sent — the backend derives it from its own geofence.
  @override
  Future<AttendanceRecord> clockIn({
    required AttendanceStatus mode,
    required double lat,
    required double lng,
    required double accuracy,
  }) async {
    final response = await dio.post('/attendance/clock-in', data: {
      'mode': mode.name,
      'lat': lat,
      'lng': lng,
      'accuracy': accuracy,
    });
    return AttendanceRecord.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> clockOut() async {
    await dio.post('/attendance/clock-out');
  }

  @override
  Future<List<AttendanceRecord>> getHistory() async {
    try {
      final response = await dio.get('/attendance/history');
      if (response.data == null || response.data is! List) {
        return [];
      }
      return (response.data as List)
          .whereType<Map<String, dynamic>>()
          .map((e) => AttendanceRecord.fromJson(e))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<ShiftInfo> getShift() async {
    final now = DateTime.now();
    final defaultShift = ShiftInfo(
      name: 'Standard Shift',
      startTime: DateTime(now.year, now.month, now.day, 9, 0),
      endTime: DateTime(now.year, now.month, now.day, 17, 0),
    );
    try {
      final response = await dio.get('/attendance/shift');
      if (response.data == null || response.data is! Map) {
        return defaultShift;
      }
      return ShiftInfo.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      return defaultShift;
    }
  }

  @override
  Future<OvertimeRequest> requestOvertime({
    required DateTime requestedStartAt,
    required DateTime requestedEndAt,
    required String reason,
  }) async {
    final response = await dio.post('/overtime/requests', data: {
      'requestedStartAt': requestedStartAt.toUtc().toIso8601String(),
      'requestedEndAt': requestedEndAt.toUtc().toIso8601String(),
      'reason': reason,
    });
    return OvertimeRequest.fromJson(_asJsonMap(response.data));
  }

  @override
  Future<List<OvertimeRequest>> getMyOvertimeRequests() async {
    final response = await dio.get('/overtime/requests/mine');
    return _asJsonList(response.data)
        .map(OvertimeRequest.fromJson)
        .toList(growable: false);
  }

  @override
  Future<List<OvertimeRequest>> getPendingOvertimeApprovals() async {
    final response = await dio.get('/overtime/approvals/pending');
    return _asJsonList(response.data)
        .map(OvertimeRequest.fromJson)
        .toList(growable: false);
  }

  @override
  Future<OvertimeRequest> approveOvertimeAsTeamLead(
    String requestId, {
    String? comment,
  }) =>
      _decide('/overtime/requests/$requestId/team-lead/approve', comment);

  @override
  Future<OvertimeRequest> rejectOvertimeAsTeamLead(
    String requestId, {
    String? comment,
  }) =>
      _decide('/overtime/requests/$requestId/team-lead/reject', comment);

  @override
  Future<OvertimeRequest> approveOvertimeAsHr(
    String requestId, {
    String? comment,
  }) =>
      _decide('/overtime/requests/$requestId/hr/approve', comment);

  @override
  Future<OvertimeRequest> rejectOvertimeAsHr(
    String requestId, {
    String? comment,
  }) =>
      _decide('/overtime/requests/$requestId/hr/reject', comment);

  @override
  Future<OvertimeSession> startOvertimeSession(
    String requestId, {
    required double lat,
    required double lng,
    required double accuracy,
  }) async {
    final response = await dio.post(
        '/overtime/requests/$requestId/session/start',
        data: {'lat': lat, 'lng': lng, 'accuracy': accuracy});
    return OvertimeSession.fromJson(_asJsonMap(response.data));
  }

  @override
  Future<OvertimeSession> endOvertimeSession(
    String sessionId, {
    required double lat,
    required double lng,
    required double accuracy,
  }) async {
    final response = await dio.post('/overtime/sessions/$sessionId/end',
        data: {'lat': lat, 'lng': lng, 'accuracy': accuracy});
    return OvertimeSession.fromJson(_asJsonMap(response.data));
  }

  Future<OvertimeRequest> _decide(String path, String? comment) async {
    final normalizedComment = comment?.trim();
    final response = await dio.post(path, data: {
      if (normalizedComment?.isNotEmpty ?? false) 'comment': normalizedComment,
    });
    return OvertimeRequest.fromJson(_asJsonMap(response.data));
  }

  Map<String, dynamic> _asJsonMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw StateError('Expected an object response from the HR API');
  }

  List<Map<String, dynamic>> _asJsonList(dynamic value) {
    if (value is! List) {
      throw StateError('Expected a list response from the HR API');
    }
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  @override
  Future<void> updateTodayMode(AttendanceStatus mode) async {
    await dio.patch('/attendance/today/mode', data: {'mode': mode.name});
  }

  @override
  Future<void> startBreak() async {
    await dio.post('/attendance/break/start');
  }

  @override
  Future<void> endBreak() async {
    await dio.post('/attendance/break/end');
  }
}
