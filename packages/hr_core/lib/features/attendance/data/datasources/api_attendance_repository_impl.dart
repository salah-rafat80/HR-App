import 'package:dio/dio.dart';
import '../../domain/entities/attendance_enums.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/shift_info.dart';
import '../../domain/repositories/attendance_repository.dart';

class ApiAttendanceRepositoryImpl implements AttendanceRepository {
  final Dio dio;

  ApiAttendanceRepositoryImpl({required this.dio});

  @override
  Future<AttendanceRecord> getTodayStatus() async {
    final response = await dio.get('/attendance/today');
    return AttendanceRecord.fromJson(response.data);
  }

  @override
  Future<void> clockIn(String locationLabel, AttendanceStatus mode) async {
    await dio.post('/attendance/clock-in', data: {
      'locationLabel': locationLabel,
      'mode': mode.name,
    });
  }

  @override
  Future<void> clockOut() async {
    await dio.post('/attendance/clock-out');
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
  Future<void> startBreak() async {
    await dio.post('/attendance/break/start');
  }

  @override
  Future<void> endBreak() async {
    await dio.post('/attendance/break/end');
  }
}
