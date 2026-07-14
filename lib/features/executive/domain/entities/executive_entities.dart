import 'package:equatable/equatable.dart';

class ExecutiveSummary extends Equatable {
  final int totalEmployees;
  final double presentPercent;
  final double onLeavePercent;
  final double turnoverPercent;
  final double avgKpiScorePercent;

  const ExecutiveSummary({
    required this.totalEmployees,
    required this.presentPercent,
    required this.onLeavePercent,
    required this.turnoverPercent,
    required this.avgKpiScorePercent,
  });

  @override
  List<Object?> get props => [totalEmployees, presentPercent, onLeavePercent, turnoverPercent, avgKpiScorePercent];
}

class TrendPoint extends Equatable {
  final String label;
  final double value;

  const TrendPoint({required this.label, required this.value});

  @override
  List<Object?> get props => [label, value];
}

class DeptHeadcount extends Equatable {
  final String department;
  final int count;

  const DeptHeadcount({required this.department, required this.count});

  @override
  List<Object?> get props => [department, count];
}
