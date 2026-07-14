import '../entities/system_config_entities.dart';
import '../../../leave/domain/entities/leave_enums.dart';

abstract class SystemConfigRepository {
  Future<List<LeaveTypeConfig>> getLeaveTypeConfigs();
  Future<void> updateLeaveTypeConfig(LeaveType type, int days);
  Future<List<Holiday>> getHolidays();
  Future<void> addHoliday(String name, DateTime date);
  Future<List<DepartmentConfig>> getDepartments();
  Future<void> addDepartment(String name);
}
