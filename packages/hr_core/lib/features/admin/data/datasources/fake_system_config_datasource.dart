import '../../domain/entities/system_config_entities.dart';
import '../../../leave/domain/entities/leave_enums.dart';
import '../../../../core/enums/role_enums.dart';

class FakeSystemConfigDataSource {
  final List<LeaveTypeConfig> _leaveTypes = [
    const LeaveTypeConfig(type: LeaveType.annual, defaultDaysPerYear: 21),
    const LeaveTypeConfig(type: LeaveType.sick, defaultDaysPerYear: 14),
    const LeaveTypeConfig(type: LeaveType.emergency, defaultDaysPerYear: 3),
    const LeaveTypeConfig(type: LeaveType.maternityPaternity, defaultDaysPerYear: 90),
    const LeaveTypeConfig(type: LeaveType.unpaid, defaultDaysPerYear: 0),
    const LeaveTypeConfig(type: LeaveType.study, defaultDaysPerYear: 10),
    const LeaveTypeConfig(type: LeaveType.hajj, defaultDaysPerYear: 15),
    const LeaveTypeConfig(type: LeaveType.bereavement, defaultDaysPerYear: 3),
  ];

  final List<Holiday> _holidays = [
    Holiday(name: 'Eid Al Fitr', date: DateTime(DateTime.now().year, 4, 10)),
    Holiday(name: 'Eid Al Adha', date: DateTime(DateTime.now().year, 6, 16)),
    Holiday(name: 'National Day', date: DateTime(DateTime.now().year, 9, 23)),
    Holiday(name: 'Foundation Day', date: DateTime(DateTime.now().year, 2, 22)),
  ];

  final List<DepartmentConfig> _departments = [
    const DepartmentConfig(name: 'Engineering', headcount: 45),
    const DepartmentConfig(name: 'Sales', headcount: 20),
    const DepartmentConfig(name: 'HR', headcount: 5),
    const DepartmentConfig(name: 'Finance', headcount: 8),
  ];

  Future<List<LeaveTypeConfig>> getLeaveTypeConfigs() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _leaveTypes;
  }

  Future<void> updateLeaveTypeConfig(LeaveType type, int days) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _leaveTypes.indexWhere((l) => l.type == type);
    if (index != -1) {
      _leaveTypes[index] = _leaveTypes[index].copyWith(defaultDaysPerYear: days);
    }
  }

  Future<List<Holiday>> getHolidays() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _holidays;
  }

  Future<void> addHoliday(String name, DateTime date) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _holidays.add(Holiday(name: name, date: date));
  }

  Future<List<DepartmentConfig>> getDepartments() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _departments;
  }

  Future<void> addDepartment(String name) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _departments.add(DepartmentConfig(name: name, headcount: 0));
  }

  // Phase 11 Extensions

  final List<RolePermission> _rolePermissions = [
    const RolePermission(role: UserRole.employee, featureKey: 'approveLeave', allowed: false),
    const RolePermission(role: UserRole.employee, featureKey: 'viewPayroll', allowed: false),
    const RolePermission(role: UserRole.employee, featureKey: 'systemConfig', allowed: false),

    const RolePermission(role: UserRole.manager, featureKey: 'approveLeave', allowed: true),
    const RolePermission(role: UserRole.manager, featureKey: 'viewPayroll', allowed: false),
    const RolePermission(role: UserRole.manager, featureKey: 'systemConfig', allowed: false),

    const RolePermission(role: UserRole.hrAdmin, featureKey: 'approveLeave', allowed: true),
    const RolePermission(role: UserRole.hrAdmin, featureKey: 'viewPayroll', allowed: true),
    const RolePermission(role: UserRole.hrAdmin, featureKey: 'systemConfig', allowed: false),

    const RolePermission(role: UserRole.superAdmin, featureKey: 'approveLeave', allowed: true),
    const RolePermission(role: UserRole.superAdmin, featureKey: 'viewPayroll', allowed: true),
    const RolePermission(role: UserRole.superAdmin, featureKey: 'systemConfig', allowed: true),
  ];

  CompanySettings _companySettings = const CompanySettings(
    companyName: 'Acme Corp',
    workWeekDays: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu'],
    timezoneLabel: 'Arabian Standard Time',
  );

  final List<IntegrationToggle> _integrations = [
    const IntegrationToggle(name: 'Slack', enabled: true),
    const IntegrationToggle(name: 'WhatsApp Alerts', enabled: false),
    const IntegrationToggle(name: 'Bank Payroll Export', enabled: true),
    const IntegrationToggle(name: 'Google Calendar', enabled: false),
  ];

  Future<List<RolePermission>> getRolePermissions() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _rolePermissions;
  }

  Future<void> toggleRolePermission(UserRole role, String featureKey) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _rolePermissions.indexWhere((r) => r.role == role && r.featureKey == featureKey);
    if (index != -1) {
      _rolePermissions[index] = _rolePermissions[index].copyWith(allowed: !_rolePermissions[index].allowed);
    }
  }

  Future<CompanySettings> getCompanySettings() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _companySettings;
  }

  Future<void> updateCompanySettings(CompanySettings draft) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _companySettings = draft;
  }

  Future<List<IntegrationToggle>> getIntegrations() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _integrations;
  }

  Future<void> toggleIntegration(String name) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _integrations.indexWhere((i) => i.name == name);
    if (index != -1) {
      _integrations[index] = _integrations[index].copyWith(enabled: !_integrations[index].enabled);
    }
  }
}
