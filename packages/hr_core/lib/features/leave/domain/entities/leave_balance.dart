import 'leave_enums.dart';

class LeaveBalance {
  final LeaveType type;
  final int daysUsed;
  final int daysTotal;
  final int? year;
  final double? entitledDays;
  final double? adjustmentDays;
  final double? reservedDays;
  final double? usedDays;

  const LeaveBalance({
    required this.type,
    required this.daysUsed,
    required this.daysTotal,
    this.year,
    this.entitledDays,
    this.adjustmentDays,
    this.reservedDays,
    this.usedDays,
  });

  int get daysLeft => daysTotal - daysUsed;

  double get availableDays {
    final entitled = entitledDays ?? daysTotal.toDouble();
    final adjustment = adjustmentDays ?? 0.0;
    final reserved = reservedDays ?? 0.0;
    final used = usedDays ?? daysUsed.toDouble();
    return entitled + adjustment - reserved - used;
  }

  factory LeaveBalance.fromJson(Map<String, dynamic> json) {
    return LeaveBalance(
      type: LeaveType.values.firstWhere(
        (e) => e.name.toLowerCase() == json['type']?.toString().toLowerCase(),
        orElse: () => LeaveType.annual,
      ),
      daysUsed: json['daysUsed'] as int? ?? 0,
      daysTotal: json['daysTotal'] as int? ?? 0,
      year: json['year'] as int?,
      entitledDays: double.tryParse(json['entitledDays']?.toString() ?? ''),
      adjustmentDays: double.tryParse(json['adjustmentDays']?.toString() ?? ''),
      reservedDays: double.tryParse(json['reservedDays']?.toString() ?? ''),
      usedDays: double.tryParse(json['usedDays']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'daysUsed': daysUsed,
      'daysTotal': daysTotal,
      if (year != null) 'year': year,
      if (entitledDays != null) 'entitledDays': entitledDays,
      if (adjustmentDays != null) 'adjustmentDays': adjustmentDays,
      if (reservedDays != null) 'reservedDays': reservedDays,
      if (usedDays != null) 'usedDays': usedDays,
    };
  }
}
