import 'package:dio/dio.dart';
import '../../domain/entities/attendance_enums.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/shift_info.dart';
import '../../domain/repositories/attendance_repository.dart';

class ApiAttendanceRepositoryImpl implements AttendanceRepository {
  final Dio dio;
  AttendanceRecord? _localTodayStatus;

  ApiAttendanceRepositoryImpl({required this.dio});

  @override
  Future<AttendanceRecord> getTodayStatus() async {
    try {
      final response = await dio.get('/attendance/today');
      final record = AttendanceRecord.fromJson(response.data);
      if (record.clockInTime != null) {
        _localTodayStatus = record;
      }
      return record;
    } catch (_) {
      return _localTodayStatus ?? AttendanceRecord(
        date: DateTime.now(),
        status: AttendanceStatus.none,
        locationLabel: 'none',
      );
    }
  }

  @override
  Future<void> clockIn({
    required String locationLabel,
    required AttendanceStatus mode,
    double? lat,
    double? lng,
    double? accuracy,
  }) async {
    final now = DateTime.now();
    _localTodayStatus = AttendanceRecord(
      date: now,
      clockInTime: now,
      status: mode,
      locationLabel: locationLabel,
    );

    try {
      final response = await dio.post('/attendance/clock-in', data: {
        'locationLabel': locationLabel,
        'mode': mode.name,
        'lat': lat,
        'lng': lng,
        'accuracy': accuracy,
      });
      if (response.data != null) {
        _localTodayStatus = AttendanceRecord.fromJson(response.data);
      }
    } catch (_) {
      // Keep local in-memory record if Dio fails
    }
  }

  @override
  Future<void> clockOut() async {
    final now = DateTime.now();
    if (_localTodayStatus != null) {
      _localTodayStatus = _localTodayStatus!.copyWith(clockOutTime: now);
    } else {
      _localTodayStatus = AttendanceRecord(
        date: now,
        clockInTime: now,
        clockOutTime: now,
        status: AttendanceStatus.present,
        locationLabel: 'Main Office',
      );
    }

    try {
      await dio.post('/attendance/clock-out');
    } catch (_) {
      // Keep local in-memory record if Dio fails
    }
  }


  @override
  Future<GeofenceStatus> getGeofenceStatus({required double lat, required double lng}) async {
    final response = await dio.get('/attendance/geofence-status', queryParameters: {
      'lat': lat,
      'lng': lng,
    });
    return GeofenceStatus(
      withinRange: response.data['withinRange'],
      distanceMeters: response.data['distanceMeters']?.toDouble() ?? 0.0,
      allowedRadiusMeters: response.data['allowedRadiusMeters']?.toDouble() ?? 200.0,
    );
  }



  @override
  Future<List<AttendanceRecord>> getHistory() async {
    List<AttendanceRecord> list = [];
    try {
      final response = await dio.get('/attendance/history');
      list = (response.data as List).map((e) => AttendanceRecord.fromJson(e)).toList();
    } catch (_) {}

    if (_localTodayStatus != null && _localTodayStatus!.clockInTime != null) {
      final hasToday = list.any((r) =>
          r.date.year == _localTodayStatus!.date.year &&
          r.date.month == _localTodayStatus!.date.month &&
          r.date.day == _localTodayStatus!.date.day);
      if (hasToday) {
        final index = list.indexWhere((r) =>
            r.date.year == _localTodayStatus!.date.year &&
            r.date.month == _localTodayStatus!.date.month &&
            r.date.day == _localTodayStatus!.date.day);
        list[index] = _localTodayStatus!;
      } else {
        list.insert(0, _localTodayStatus!);
      }
    }
    return list;
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
  Future<void> startBreak() async {
    await dio.post('/attendance/break/start');
  }

  @override
  Future<void> endBreak() async {
    await dio.post('/attendance/break/end');
  }
}
