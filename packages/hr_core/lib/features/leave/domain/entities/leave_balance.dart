import 'leave_enums.dart';

class LeaveBalance {
  final LeaveType type;
  final int daysUsed;
  final int daysTotal;

  const LeaveBalance({
    required this.type,
    required this.daysUsed,
    required this.daysTotal,
  });

  int get daysLeft => daysTotal - daysUsed;

  factory LeaveBalance.fromJson(Map<String, dynamic> json) {
    return LeaveBalance(
      type: LeaveType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => LeaveType.annual,
      ),
      daysUsed: json['daysUsed'] as int,
      daysTotal: json['daysTotal'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'daysUsed': daysUsed,
      'daysTotal': daysTotal,
    };
  }
}
