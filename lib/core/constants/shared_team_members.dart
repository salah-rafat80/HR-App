import '../../features/team/domain/entities/team_member.dart';

class SharedTeamMembers {
  static final List<TeamMember> members = [
    const TeamMember(id: 'emp_1', name: 'Ahmed Salem', title: 'Frontend Developer', department: 'Engineering', kpiScorePercent: 0.85, leaveStatus: 'present'),
    const TeamMember(id: 'emp_2', name: 'Mona Zaki', title: 'Backend Developer', department: 'Engineering', kpiScorePercent: 0.92, leaveStatus: 'present'),
    const TeamMember(id: 'emp_3', name: 'Omar Farooq', title: 'QA Engineer', department: 'Engineering', kpiScorePercent: 0.78, leaveStatus: 'onLeave'),
    const TeamMember(id: 'emp_4', name: 'Sara Ali', title: 'Product Manager', department: 'Product', kpiScorePercent: 0.88, leaveStatus: 'wfh'),
    const TeamMember(id: 'emp_5', name: 'Tariq Hassan', title: 'UI/UX Designer', department: 'Product', kpiScorePercent: 0.95, leaveStatus: 'present'),
    const TeamMember(id: 'emp_6', name: 'Nour Youssef', title: 'HR Generalist', department: 'HR', kpiScorePercent: 0.80, leaveStatus: 'present'),
  ];
}
