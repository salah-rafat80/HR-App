import 'package:hr_core/core/enums/role_enums.dart';
import 'package:hr_core/features/admin/domain/entities/system_config_entities.dart';
import 'package:hr_core/features/admin/domain/repositories/system_config_repository.dart';
import 'package:hr_core/features/leave/domain/entities/leave_enums.dart';
import '../../../../core/bloc/web_cubits.dart';

class SystemConfigState {
  final List<LeaveTypeConfig> leaveTypes;
  final List<Holiday> holidays;
  final List<DepartmentConfig> departments;
  final List<RolePermission> rolePermissions;
  final CompanySettings companySettings;
  final List<IntegrationToggle> integrations;

  const SystemConfigState({
    required this.leaveTypes,
    required this.holidays,
    required this.departments,
    required this.rolePermissions,
    required this.companySettings,
    required this.integrations,
  });

  SystemConfigState copyWith({
    List<LeaveTypeConfig>? leaveTypes,
    List<Holiday>? holidays,
    List<DepartmentConfig>? departments,
    List<RolePermission>? rolePermissions,
    CompanySettings? companySettings,
    List<IntegrationToggle>? integrations,
  }) {
    return SystemConfigState(
      leaveTypes: leaveTypes ?? this.leaveTypes,
      holidays: holidays ?? this.holidays,
      departments: departments ?? this.departments,
      rolePermissions: rolePermissions ?? this.rolePermissions,
      companySettings: companySettings ?? this.companySettings,
      integrations: integrations ?? this.integrations,
    );
  }
}

class SystemConfigCubit extends WebCubit<SystemConfigState> {
  final SystemConfigRepository _repo;

  SystemConfigCubit(this._repo) : super(() => _fetch(_repo));

  static Future<SystemConfigState> _fetch(SystemConfigRepository repo) async {
    final leaveTypes = await repo.getLeaveTypeConfigs();
    final holidays = await repo.getHolidays();
    final departments = await repo.getDepartments();
    final rolePermissions = await repo.getRolePermissions();
    final companySettings = await repo.getCompanySettings();
    final integrations = await repo.getIntegrations();
    return SystemConfigState(
      leaveTypes: leaveTypes,
      holidays: holidays,
      departments: departments,
      rolePermissions: rolePermissions,
      companySettings: companySettings,
      integrations: integrations,
    );
  }

  Future<void> updateLeaveType(LeaveType type, int days) async {
    await _repo.updateLeaveTypeConfig(type, days);
    _updateState((s) => s.copyWith(
      leaveTypes: s.leaveTypes.map((l) => l.type == type ? l.copyWith(defaultDaysPerYear: days) : l).toList(),
    ));
  }

  Future<void> addHoliday(String name, DateTime date) async {
    await _repo.addHoliday(name, date);
    load();
  }

  Future<void> addDepartment(String name) async {
    await _repo.addDepartment(name);
    _updateState((s) => s.copyWith(
      departments: [...s.departments, DepartmentConfig(name: name, headcount: 0)],
    ));
  }

  Future<void> toggleRolePermission(UserRole role, String featureKey) async {
    await _repo.toggleRolePermission(role, featureKey);
    _updateState((s) => s.copyWith(
      rolePermissions: s.rolePermissions.map((r) {
        if (r.role == role && r.featureKey == featureKey) return r.copyWith(allowed: !r.allowed);
        return r;
      }).toList(),
    ));
  }

  Future<void> updateCompanySettings(CompanySettings settings) async {
    await _repo.updateCompanySettings(settings);
    _updateState((s) => s.copyWith(companySettings: settings));
  }

  Future<void> toggleIntegration(String name) async {
    await _repo.toggleIntegration(name);
    _updateState((s) => s.copyWith(
      integrations: s.integrations.map((i) => i.name == name ? i.copyWith(enabled: !i.enabled) : i).toList(),
    ));
  }

  void _updateState(SystemConfigState Function(SystemConfigState) updater) {
    final current = state;
    if (current is WebSuccess<SystemConfigState>) {
      emit(WebSuccess<SystemConfigState>(updater(current.data)));
    }
  }
}
