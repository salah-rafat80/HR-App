import '../entities/leave_balance.dart';
import '../entities/leave_enums.dart';
import '../entities/leave_request.dart';
import '../entities/team_leave_entry.dart';
import '../../../../core/enums/role_enums.dart';

abstract class LeaveRepository {
  Future<List<LeaveBalance>> getBalances();
  Future<List<LeaveRequest>> getMyRequests();
  Future<void> applyLeave(LeaveRequest draft);
  Future<void> cancelRequest(String id);
  Future<List<TeamLeaveEntry>> getTeamCalendar();
  Future<void> requestEncashment(LeaveType type, int days);
  Future<void> advanceApprovalStep(String requestId);
  Future<List<LeaveRequest>> getPendingApprovals(ApprovalScope scope);
  Future<void> approveRequest(String requestId);
  Future<void> rejectRequest(String requestId);
}
