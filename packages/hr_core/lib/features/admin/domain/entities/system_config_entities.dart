import 'package:equatable/equatable.dart';
import '../../../leave/domain/entities/leave_enums.dart';
import '../../../../core/enums/role_enums.dart';

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

class RolePermission extends Equatable {
  final UserRole role;
  final String featureKey;
  final bool allowed;

  const RolePermission({required this.role, required this.featureKey, required this.allowed});

  RolePermission copyWith({bool? allowed}) {
    return RolePermission(role: role, featureKey: featureKey, allowed: allowed ?? this.allowed);
  }

  @override
  List<Object?> get props => [role, featureKey, allowed];
}

class CompanySettings extends Equatable {
  final String companyName;
  final List<String> workWeekDays;
  final String timezoneLabel;

  const CompanySettings({required this.companyName, required this.workWeekDays, required this.timezoneLabel});

  CompanySettings copyWith({String? companyName, List<String>? workWeekDays, String? timezoneLabel}) {
    return CompanySettings(
      companyName: companyName ?? this.companyName,
      workWeekDays: workWeekDays ?? this.workWeekDays,
      timezoneLabel: timezoneLabel ?? this.timezoneLabel,
    );
  }

  @override
  List<Object?> get props => [companyName, workWeekDays, timezoneLabel];
}

class IntegrationToggle extends Equatable {
  final String name;
  final bool enabled;

  const IntegrationToggle({required this.name, required this.enabled});

  IntegrationToggle copyWith({bool? enabled}) {
    return IntegrationToggle(name: name, enabled: enabled ?? this.enabled);
  }

  @override
  List<Object?> get props => [name, enabled];
}
