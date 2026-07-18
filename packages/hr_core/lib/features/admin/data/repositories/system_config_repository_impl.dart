import '../../domain/entities/system_config_entities.dart';
import '../../domain/repositories/system_config_repository.dart';
import '../datasources/fake_system_config_datasource.dart';
import '../../../leave/domain/entities/leave_enums.dart';
import '../../../../core/enums/role_enums.dart';

class SystemConfigRepositoryImpl implements SystemConfigRepository {
  final FakeSystemConfigDataSource _dataSource;

  SystemConfigRepositoryImpl(this._dataSource);

  @override
  Future<void> addDepartment(String name) => _dataSource.addDepartment(name);

  @override
  Future<void> addHoliday(String name, DateTime date) => _dataSource.addHoliday(name, date);

  @override
  Future<List<DepartmentConfig>> getDepartments() => _dataSource.getDepartments();

  @override
  Future<List<Holiday>> getHolidays() => _dataSource.getHolidays();

  @override
  Future<List<LeaveTypeConfig>> getLeaveTypeConfigs() => _dataSource.getLeaveTypeConfigs();

  @override
  Future<void> updateLeaveTypeConfig(LeaveType type, int days) => _dataSource.updateLeaveTypeConfig(type, days);

  @override
  Future<List<RolePermission>> getRolePermissions() => _dataSource.getRolePermissions();

  @override
  Future<void> toggleRolePermission(UserRole role, String featureKey) => _dataSource.toggleRolePermission(role, featureKey);

  @override
  Future<CompanySettings> getCompanySettings() => _dataSource.getCompanySettings();

  @override
  Future<void> updateCompanySettings(CompanySettings draft) => _dataSource.updateCompanySettings(draft);

  @override
  Future<List<IntegrationToggle>> getIntegrations() => _dataSource.getIntegrations();

  @override
  Future<void> toggleIntegration(String name) => _dataSource.toggleIntegration(name);
}
