import '../entities/system_config_entities.dart';
import '../../../leave/domain/entities/leave_enums.dart';
import '../../../../core/enums/role_enums.dart';

abstract class SystemConfigRepository {
  Future<List<LeaveTypeConfig>> getLeaveTypeConfigs();
  Future<void> updateLeaveTypeConfig(LeaveType type, int days);
  Future<List<Holiday>> getHolidays();
  Future<void> addHoliday(String name, DateTime date);
  Future<List<DepartmentConfig>> getDepartments();
  Future<void> addDepartment(String name);

  // Full forms:
  Future<List<RolePermission>> getRolePermissions();
  Future<void> toggleRolePermission(UserRole role, String featureKey);
  
  Future<CompanySettings> getCompanySettings();
  Future<void> updateCompanySettings(CompanySettings draft);
  
  Future<List<IntegrationToggle>> getIntegrations();
  Future<void> toggleIntegration(String name);
}
