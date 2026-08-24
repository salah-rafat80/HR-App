import '../../domain/entities/leave_balance.dart';
import '../../domain/entities/leave_enums.dart';
import '../../domain/entities/leave_request.dart';
import '../../domain/entities/team_leave_entry.dart';
import '../../domain/entities/leave_policy.dart';
import '../../domain/repositories/leave_repository.dart';
import '../datasources/fake_leave_datasource.dart';
import '../../../../core/enums/role_enums.dart';

class LeaveRepositoryImpl implements LeaveRepository {
  final FakeLeaveDataSource _dataSource;

  LeaveRepositoryImpl(this._dataSource);

  @override
  Future<void> advanceApprovalStep(String requestId) =>
      _dataSource.advanceApprovalStep(requestId);

  @override
  Future<void> applyLeave(LeaveRequest draft) => _dataSource.applyLeave(draft);

  @override
  Future<void> cancelRequest(String id) => _dataSource.cancelRequest(id);

  @override
  Future<List<LeaveBalance>> getBalances() => _dataSource.getBalances();

  @override
  Future<List<LeaveRequest>> getMyRequests() => _dataSource.getMyRequests();

  @override
  Future<List<TeamLeaveEntry>> getTeamCalendar() =>
      _dataSource.getTeamCalendar();

  @override
  Future<void> requestEncashment(LeaveType type, int days) =>
      _dataSource.requestEncashment(type, days);

  @override
  Future<List<LeaveRequest>> getPendingApprovals(ApprovalScope scope) =>
      _dataSource.getPendingApprovals(scope);

  @override
  Future<void> approveRequest(String requestId) =>
      _dataSource.approveRequest(requestId);

  @override
  Future<void> rejectRequest(String requestId) =>
      _dataSource.rejectRequest(requestId);

  // ==========================================
  // New Interface Implementations (Stubs)
  // ==========================================

  @override
  Future<void> cancelRequestWithReason(String id, String reason) {
    throw UnimplementedError(
        'cancelRequestWithReason not implemented in Fake repository');
  }

  @override
  Future<void> approveRequestWithComment(String requestId, String? comment) {
    throw UnimplementedError(
        'approveRequestWithComment not implemented in Fake repository');
  }

  @override
  Future<void> rejectRequestWithComment(String requestId, String comment) {
    throw UnimplementedError(
        'rejectRequestWithComment not implemented in Fake repository');
  }

  @override
  Future<List<LeavePolicy>> getPolicies() {
    throw UnimplementedError('getPolicies not implemented in Fake repository');
  }

  @override
  Future<void> createPolicy(LeavePolicy policy) {
    throw UnimplementedError('createPolicy not implemented in Fake repository');
  }

  @override
  Future<void> updatePolicy(LeaveType type, Map<String, dynamic> data) {
    throw UnimplementedError('updatePolicy not implemented in Fake repository');
  }

  @override
  Future<void> togglePolicy(LeaveType type) {
    throw UnimplementedError('togglePolicy not implemented in Fake repository');
  }

  @override
  Future<Map<String, dynamic>> getBalancesAdmin({
    required int page,
    required int limit,
    String? employeeId,
    String? department,
    String? branchId,
    int? year,
  }) {
    throw UnimplementedError(
        'getBalancesAdmin not implemented in Fake repository');
  }

  @override
  Future<void> createBalance({
    required String userId,
    required LeaveType type,
    required int year,
    required double entitledDays,
  }) {
    throw UnimplementedError(
        'createBalance not implemented in Fake repository');
  }

  @override
  Future<void> adjustBalance({
    required String balanceId,
    required double adjustmentDays,
    required String reason,
  }) {
    throw UnimplementedError(
        'adjustBalance not implemented in Fake repository');
  }

  @override
  Future<Map<String, dynamic>> getCompanyApprovalConfig() {
    throw UnimplementedError(
        'getCompanyApprovalConfig not implemented in Fake repository');
  }

  @override
  Future<void> updateCompanyApprovalConfig(String? finalHrApproverId) {
    throw UnimplementedError(
        'updateCompanyApprovalConfig not implemented in Fake repository');
  }

  @override
  Future<Map<String, dynamic>> previewLeave({
    required LeaveType type,
    required DateTime startDate,
    required DateTime endDate,
    required bool isHalfDay,
    String? halfDayPeriod,
    required String reason,
  }) {
    throw UnimplementedError('previewLeave not implemented in Fake repository');
  }

  @override
  Future<List<Map<String, dynamic>>> getEmployeesForPicker() {
    throw UnimplementedError(
        'getEmployeesForPicker not implemented in Fake repository');
  }
}
