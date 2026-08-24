import '../entities/leave_balance.dart';
import '../entities/leave_enums.dart';
import '../entities/leave_request.dart';
import '../entities/team_leave_entry.dart';
import '../entities/leave_policy.dart';
import '../../../../core/enums/role_enums.dart';

abstract class LeaveRepository {
  Future<List<LeaveBalance>> getBalances();
  Future<List<LeaveRequest>> getMyRequests();
  Future<void> applyLeave(LeaveRequest draft);
  Future<void> cancelRequest(String id);
  Future<void> cancelRequestWithReason(String id, String reason);
  Future<List<TeamLeaveEntry>> getTeamCalendar();
  Future<void> requestEncashment(LeaveType type, int days);
  Future<void> advanceApprovalStep(String requestId);
  Future<List<LeaveRequest>> getPendingApprovals(ApprovalScope scope);
  Future<void> approveRequest(String requestId);
  Future<void> approveRequestWithComment(String requestId, String? comment);
  Future<void> rejectRequest(String requestId);
  Future<void> rejectRequestWithComment(String requestId, String comment);

  // Leave Policies (HR)
  Future<List<LeavePolicy>> getPolicies();
  Future<void> createPolicy(LeavePolicy policy);
  Future<void> updatePolicy(LeaveType type, Map<String, dynamic> data);
  Future<void> togglePolicy(LeaveType type);

  // Leave Balances (HR)
  Future<Map<String, dynamic>> getBalancesAdmin({
    required int page,
    required int limit,
    String? employeeId,
    String? department,
    String? branchId,
    int? year,
  });
  Future<void> createBalance({
    required String userId,
    required LeaveType type,
    required int year,
    required double entitledDays,
  });
  Future<void> adjustBalance({
    required String balanceId,
    required double adjustmentDays,
    required String reason,
  });

  // Company Configurations
  Future<Map<String, dynamic>> getCompanyApprovalConfig();
  Future<void> updateCompanyApprovalConfig(String? finalHrApproverId);

  // Employee Preflight Preview
  Future<Map<String, dynamic>> previewLeave({
    required LeaveType type,
    required DateTime startDate,
    required DateTime endDate,
    required bool isHalfDay,
    String? halfDayPeriod,
    required String reason,
  });

  // Safe Employee Picker
  Future<List<Map<String, dynamic>>> getEmployeesForPicker();
}
