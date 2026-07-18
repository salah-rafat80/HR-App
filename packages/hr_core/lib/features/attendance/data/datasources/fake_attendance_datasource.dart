import '../../domain/entities/attendance_enums.dart';
import '../../domain/entities/attendance_record.dart';
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

  final ShiftInfo _shift = ShiftInfo(
    name: 'Morning Shift',
    startTime: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 9, 0),
    endTime: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 17, 0),
  );

  Future<AttendanceRecord> getTodayStatus() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return _todayRecord;
  }

  Future<void> clockIn(String locationLabel, AttendanceStatus mode) async {
    await Future.delayed(const Duration(milliseconds: 800));
    _todayRecord = _todayRecord.copyWith(
      clockInTime: DateTime.now(),
      status: mode,
      locationLabel: locationLabel,
    );
  }

  Future<void> clockOut() async {
    await Future.delayed(const Duration(milliseconds: 800));
    _todayRecord = _todayRecord.copyWith(
      clockOutTime: DateTime.now(),
    );
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
  }

  Future<void> startBreak() async {
    await Future.delayed(const Duration(milliseconds: 400));
  }

  Future<void> endBreak() async {
    await Future.delayed(const Duration(milliseconds: 400));
  }
}
