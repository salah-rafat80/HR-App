import 'package:equatable/equatable.dart';
import '../../../leave/domain/entities/leave_enums.dart';

class LeaveTypeConfig extends Equatable {
  final LeaveType type;
  final int defaultDaysPerYear;

  const LeaveTypeConfig({required this.type, required this.defaultDaysPerYear});

  LeaveTypeConfig copyWith({int? defaultDaysPerYear}) {
    return LeaveTypeConfig(
      type: type,
      defaultDaysPerYear: defaultDaysPerYear ?? this.defaultDaysPerYear,
    );
  }

  @override
  List<Object?> get props => [type, defaultDaysPerYear];
}

class Holiday extends Equatable {
  final String name;
  final DateTime date;

  const Holiday({required this.name, required this.date});

  @override
  List<Object?> get props => [name, date];
}

class DepartmentConfig extends Equatable {
  final String name;
  final int headcount;

  const DepartmentConfig({required this.name, required this.headcount});

  @override
  List<Object?> get props => [name, headcount];
}
