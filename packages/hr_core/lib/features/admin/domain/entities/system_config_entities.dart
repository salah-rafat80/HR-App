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

  const CompanySettings({
    required this.companyName,
    required this.workWeekDays,
    required this.timezoneLabel,
  });

  CompanySettings copyWith({
    String? companyName,
    List<String>? workWeekDays,
    String? timezoneLabel,
  }) {
    return CompanySettings(
      companyName: companyName ?? this.companyName,
      workWeekDays: workWeekDays ?? this.workWeekDays,
      timezoneLabel: timezoneLabel ?? this.timezoneLabel,
    );
  }

  @override
  List<Object?> get props => [
        companyName,
        workWeekDays,
        timezoneLabel,
      ];
}

class OfficeBranch extends Equatable {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final int radiusMeters;
  final bool isActive;

  const OfficeBranch({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.isActive,
  });

  factory OfficeBranch.fromJson(Map<String, dynamic> json) {
    return OfficeBranch(
      id: json['id'] as String,
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radiusMeters: json['radiusMeters'] as int,
      isActive: json['isActive'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'radiusMeters': radiusMeters,
      'isActive': isActive,
    };
  }

  OfficeBranch copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    int? radiusMeters,
    bool? isActive,
  }) {
    return OfficeBranch(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        latitude,
        longitude,
        radiusMeters,
        isActive,
      ];
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
