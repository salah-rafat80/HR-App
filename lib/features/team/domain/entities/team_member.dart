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

  @override
  List<Object?> get props => [id, name, title, department, kpiScorePercent, leaveStatus];
}
