class TeamLeaveEntry {
  final String colleagueName;
  final DateTime startDate;
  final DateTime endDate;

  const TeamLeaveEntry({
    required this.colleagueName,
    required this.startDate,
    required this.endDate,
  });

  factory TeamLeaveEntry.fromJson(Map<String, dynamic> json) {
    return TeamLeaveEntry(
      colleagueName: json['colleagueName'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'colleagueName': colleagueName,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    };
  }
}
