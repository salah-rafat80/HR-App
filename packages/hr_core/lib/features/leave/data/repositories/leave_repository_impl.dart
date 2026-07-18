import '../../domain/entities/leave_balance.dart';
import '../../domain/entities/leave_enums.dart';
import '../../domain/entities/leave_request.dart';
import '../../domain/entities/team_leave_entry.dart';
import '../../domain/repositories/leave_repository.dart';
import '../datasources/fake_leave_datasource.dart';
import '../../../../core/enums/role_enums.dart';

class LeaveRepositoryImpl implements LeaveRepository {
  final FakeLeaveDataSource _dataSource;

  LeaveRepositoryImpl(this._dataSource);

  @override
  Future<void> advanceApprovalStep(String requestId) => _dataSource.advanceApprovalStep(requestId);

  @override
  Future<void> applyLeave(LeaveRequest draft) => _dataSource.applyLeave(draft);

  @override
  Future<void> cancelRequest(String id) => _dataSource.cancelRequest(id);

  @override
  Future<List<LeaveBalance>> getBalances() => _dataSource.getBalances();

  @override
  Future<List<LeaveRequest>> getMyRequests() => _dataSource.getMyRequests();

  @override
  Future<List<TeamLeaveEntry>> getTeamCalendar() => _dataSource.getTeamCalendar();

  @override
  Future<void> requestEncashment(LeaveType type, int days) => _dataSource.requestEncashment(type, days);

  @override
  Future<List<LeaveRequest>> getPendingApprovals(ApprovalScope scope) => _dataSource.getPendingApprovals(scope);

  @override
  Future<void> approveRequest(String requestId) => _dataSource.approveRequest(requestId);

  @override
  Future<void> rejectRequest(String requestId) => _dataSource.rejectRequest(requestId);
}
