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
    return AttendanceRecord.fromJson(response.data);
  }

  @override
  Future<void> clockIn({
    required String locationLabel,
    required AttendanceStatus mode,
    double? lat,
    double? lng,
    double? accuracy,
  }) async {
    await dio.post('/attendance/clock-in', data: {
      'locationLabel': locationLabel,
      'mode': mode.name,
      'lat': lat,
      'lng': lng,
      'accuracy': accuracy,
    });
  }

  @override
  Future<void> clockOut() async {
    await dio.post('/attendance/clock-out');
  }

  @override
  Future<GeofenceStatus> getGeofenceStatus({
    required double lat,
    required double lng,
  }) async {
    final response = await dio.get('/attendance/geofence-status', queryParameters: {
      'lat': lat,
      'lng': lng,
    });
    return GeofenceStatus(
      withinRange: response.data['withinRange'] ?? false,
      distanceMeters: (response.data['distanceMeters'] as num?)?.toDouble() ?? 0.0,
      allowedRadiusMeters:
          (response.data['allowedRadiusMeters'] as num?)?.toDouble() ?? 200.0,
    );
  }

  @override
  Future<List<AttendanceRecord>> getHistory() async {
    final response = await dio.get('/attendance/history');
    return (response.data as List).map((e) => AttendanceRecord.fromJson(e)).toList();
  }

  @override
  Future<ShiftInfo> getShift() async {
    final response = await dio.get('/attendance/shift');
    return ShiftInfo.fromJson(response.data);
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
        .map((e) => OvertimeRequest.fromJson(e))
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
