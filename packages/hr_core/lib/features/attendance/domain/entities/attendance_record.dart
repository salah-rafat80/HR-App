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

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      date: DateTime.parse(json['date']),
      clockInTime: json['clockInTime'] != null ? DateTime.parse(json['clockInTime']) : null,
      clockOutTime: json['clockOutTime'] != null ? DateTime.parse(json['clockOutTime']) : null,
      status: AttendanceStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => AttendanceStatus.none,
      ),
      locationLabel: json['locationLabel'] ?? 'none',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'clockInTime': clockInTime?.toIso8601String(),
      'clockOutTime': clockOutTime?.toIso8601String(),
      'status': status.name,
      'locationLabel': locationLabel,
    };
  }
}
