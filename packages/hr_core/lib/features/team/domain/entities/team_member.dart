import 'package:equatable/equatable.dart';

class TeamMember extends Equatable {
  final String id;
  final String name;
  final String title;
  final String department;
  final double kpiScorePercent;
  final String leaveStatus; // 'present', 'onLeave', 'wfh'

  const TeamMember({
    required this.id,
    required this.name,
    required this.title,
    required this.department,
    required this.kpiScorePercent,
    required this.leaveStatus,
  });

  TeamMember copyWith({
    String? name,
    String? title,
    String? department,
    double? kpiScorePercent,
    String? leaveStatus,
  }) {
    return TeamMember(
      id: id,
      name: name ?? this.name,
      title: title ?? this.title,
      department: department ?? this.department,
      kpiScorePercent: kpiScorePercent ?? this.kpiScorePercent,
      leaveStatus: leaveStatus ?? this.leaveStatus,
    );
  }

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      id: json['id'] as String,
      name: json['name'] as String,
      title: json['title'] as String? ?? '',
      department: json['department'] as String? ?? '',
      kpiScorePercent: (json['kpiScorePercent'] as num).toDouble(),
      leaveStatus: json['leaveStatus'] as String? ?? 'present',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'title': title,
      'department': department,
      'kpiScorePercent': kpiScorePercent,
      'leaveStatus': leaveStatus,
    };
  }

  @override
  List<Object?> get props => [id, name, title, department, kpiScorePercent, leaveStatus];
}
