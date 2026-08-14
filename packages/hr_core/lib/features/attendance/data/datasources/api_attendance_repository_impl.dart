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
    final response = await dio.get('/attendance/today');
    if (response.data == null || response.data is! Map) {
      return AttendanceRecord(
        date: DateTime.now(),
        status: AttendanceStatus.none,
        locationLabel: 'none',
      );
    }
    return AttendanceRecord.fromJson(response.data as Map<String, dynamic>);
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
    final response = await dio.get('/attendance/history');
    return (response.data as List)
        .map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ShiftInfo> getShift() async {
    final response = await dio.get('/attendance/shift');
    return ShiftInfo.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> requestOvertime(double hours, String reason) async {
    await dio.post('/attendance/overtime', data: {
      'hoursRequested': hours,
      'reason': reason,
    });
  }

  @override
  Future<List<OvertimeRequest>> getOvertimeRequests() async {
    final response = await dio.get('/attendance/overtime');
    return (response.data as List)
        .map((e) => OvertimeRequest.fromJson(e as Map<String, dynamic>))
        .toList();
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
