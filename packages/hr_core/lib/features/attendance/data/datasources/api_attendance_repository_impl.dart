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
  Future<void> requestOvertime(double hours, String reason) async {
    await dio.post('/attendance/overtime', data: {
      'hoursRequested': hours,
      'reason': reason,
    });
  }

  @override
  Future<List<OvertimeRequest>> getOvertimeRequests() async {
    try {
      final response = await dio.get('/attendance/overtime');
      if (response.data == null || response.data is! List) {
        return [];
      }
      return (response.data as List)
          .whereType<Map<String, dynamic>>()
          .map((e) => OvertimeRequest.fromJson(e))
          .toList();
    } catch (_) {
      return [];
    }
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
