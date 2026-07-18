import 'attendance_enums.dart';

class AttendanceRecord {
  final DateTime date;
  final DateTime? clockInTime;
  final DateTime? clockOutTime;
  final AttendanceStatus status;
  final String locationLabel;

  const AttendanceRecord({
    required this.date,
    this.clockInTime,
    this.clockOutTime,
    required this.status,
    required this.locationLabel,
  });

  AttendanceRecord copyWith({
    DateTime? date,
    DateTime? clockInTime,
    DateTime? clockOutTime,
    AttendanceStatus? status,
    String? locationLabel,
  }) {
    return AttendanceRecord(
      date: date ?? this.date,
      clockInTime: clockInTime ?? this.clockInTime,
      clockOutTime: clockOutTime ?? this.clockOutTime,
      status: status ?? this.status,
      locationLabel: locationLabel ?? this.locationLabel,
    );
  }
}
