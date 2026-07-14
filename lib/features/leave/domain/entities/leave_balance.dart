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
}
