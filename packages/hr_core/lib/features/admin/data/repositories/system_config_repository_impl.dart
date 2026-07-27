import '../../domain/entities/system_config_entities.dart';
import '../../domain/repositories/system_config_repository.dart';
import '../datasources/fake_system_config_datasource.dart';
import '../datasources/api_system_config_datasource.dart';
import '../../../leave/domain/entities/leave_enums.dart';
import '../../../../core/enums/role_enums.dart';

class SystemConfigRepositoryImpl implements SystemConfigRepository {
  final FakeSystemConfigDataSource _fakeDataSource;
  final ApiSystemConfigDataSource _apiDataSource;

  SystemConfigRepositoryImpl(this._fakeDataSource, this._apiDataSource);

  @override
  Future<void> addDepartment(String name) => _fakeDataSource.addDepartment(name);

  @override
  Future<void> addHoliday(String name, DateTime date) => _fakeDataSource.addHoliday(name, date);

  @override
  Future<List<DepartmentConfig>> getDepartments() => _fakeDataSource.getDepartments();

  @override
  Future<List<Holiday>> getHolidays() => _fakeDataSource.getHolidays();

  @override
  Future<List<LeaveTypeConfig>> getLeaveTypeConfigs() => _fakeDataSource.getLeaveTypeConfigs();

  @override
  Future<void> updateLeaveTypeConfig(LeaveType type, int days) => _fakeDataSource.updateLeaveTypeConfig(type, days);

  @override
  Future<List<RolePermission>> getRolePermissions() => _fakeDataSource.getRolePermissions();

  @override
  Future<void> toggleRolePermission(UserRole role, String featureKey) => _fakeDataSource.toggleRolePermission(role, featureKey);

  @override
  Future<CompanySettings> getCompanySettings() => _fakeDataSource.getCompanySettings();

  @override
  Future<void> updateCompanySettings(CompanySettings draft) => _fakeDataSource.updateCompanySettings(draft);

  @override
  Future<List<IntegrationToggle>> getIntegrations() => _fakeDataSource.getIntegrations();

  @override
  Future<void> toggleIntegration(String name) => _fakeDataSource.toggleIntegration(name);

  @override
  Future<List<OfficeBranch>> getBranches() async {
    try {
      return await _apiDataSource.getBranches();
    } catch (_) {
      return await _fakeDataSource.getBranches();
    }
  }

  @override
  Future<void> addBranch(OfficeBranch branch) async {
    try {
      await _apiDataSource.addBranch(branch);
    } catch (_) {
      await _fakeDataSource.addBranch(branch);
    }
  }

  @override
  Future<void> updateBranch(OfficeBranch branch) async {
    try {
      await _apiDataSource.updateBranch(branch);
    } catch (_) {
      await _fakeDataSource.updateBranch(branch);
    }
  }

  @override
  Future<void> deleteBranch(String id) async {
    try {
      await _apiDataSource.deleteBranch(id);
    } catch (_) {
      await _fakeDataSource.deleteBranch(id);
    }
  }
}

