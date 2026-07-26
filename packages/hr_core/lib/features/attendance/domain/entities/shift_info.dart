class ShiftInfo {
  final String name;
  final DateTime startTime;
  final DateTime endTime;

  const ShiftInfo({
    required this.name,
    required this.startTime,
    required this.endTime,
  });

  factory ShiftInfo.fromJson(Map<String, dynamic> json) {
    return ShiftInfo(
      name: json['shiftName'] ?? 'Shift',
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shiftName': name,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
    };
  }
}
