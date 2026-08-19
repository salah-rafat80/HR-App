import 'package:dio/dio.dart';
import '../../domain/entities/leave_balance.dart';
import '../../domain/entities/leave_enums.dart';
import '../../domain/entities/leave_request.dart';
import '../../domain/entities/team_leave_entry.dart';
import '../../domain/entities/leave_policy.dart';
import '../../../../core/enums/role_enums.dart';
import '../../domain/repositories/leave_repository.dart';

class ApiLeaveRepositoryImpl implements LeaveRepository {
  final Dio dio;

  ApiLeaveRepositoryImpl({required this.dio});

  String _formatDate(DateTime dt) {
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
  }

  @override
  Future<List<LeaveBalance>> getBalances() async {
    final response = await dio.get('/leave/balances');
    return (response.data as List).map((e) => LeaveBalance.fromJson(e)).toList();
  }

  @override
  Future<List<LeaveRequest>> getMyRequests() async {
    final response = await dio.get('/leave/my-requests');
    return (response.data as List).map((e) => LeaveRequest.fromJson(e)).toList();
  }

  @override
  Future<void> applyLeave(LeaveRequest draft) async {
    await dio.post(
      '/leave/apply',
      data: {
        'type': draft.type.name,
        'startDate': _formatDate(draft.startDate),
        'endDate': _formatDate(draft.endDate),
        'isHalfDay': draft.isHalfDay,
        'halfDayPeriod': draft.halfDayPeriod,
        'reason': draft.reason,
      },
      options: Options(headers: {'Idempotency-Key': draft.id}),
    );
  }

  @override
  Future<void> cancelRequest(String id) async {
    await cancelRequestWithReason(id, 'Cancelled by user');
  }

  @override
  Future<void> cancelRequestWithReason(String id, String reason) async {
    await dio.post(
      '/leave/$id/cancel',
      data: {'reason': reason},
    );
  }

  @override
  Future<List<TeamLeaveEntry>> getTeamCalendar() async {
    final response = await dio.get('/leave/team-calendar');
    return (response.data as List).map((e) => TeamLeaveEntry.fromJson(e)).toList();
  }

  @override
  Future<void> requestEncashment(LeaveType type, int days) async {
    throw UnimplementedError('requestEncashment not implemented on API yet');
  }

  @override
  Future<void> advanceApprovalStep(String requestId) async {
    await approveRequest(requestId);
  }

  @override
  Future<List<LeaveRequest>> getPendingApprovals(ApprovalScope scope) async {
    final response = await dio.get('/leave/pending');
    return (response.data as List).map((e) => LeaveRequest.fromJson(e)).toList();
  }

  @override
  Future<void> approveRequest(String requestId) async {
    await approveRequestWithComment(requestId, null);
  }

  @override
  Future<void> approveRequestWithComment(String requestId, String? comment) async {
    await dio.post(
      '/leave/$requestId/approve',
      data: {'comment': comment},
    );
  }

  @override
  Future<void> rejectRequest(String requestId) async {
    await rejectRequestWithComment(requestId, 'Rejected');
  }

  @override
  Future<void> rejectRequestWithComment(String requestId, String comment) async {
    await dio.post(
      '/leave/$requestId/reject',
      data: {'comment': comment},
    );
  }

  // ==========================================
  // Leave Policies (HR)
  // ==========================================

  @override
  Future<List<LeavePolicy>> getPolicies() async {
    final response = await dio.get('/leave/policies');
    return (response.data as List).map((e) => LeavePolicy.fromJson(e)).toList();
  }

  @override
  Future<void> createPolicy(LeavePolicy policy) async {
    await dio.post('/leave/policies', data: policy.toJson());
  }

  @override
  Future<void> updatePolicy(LeaveType type, Map<String, dynamic> data) async {
    await dio.patch('/leave/policies/${type.name}', data: data);
  }

  @override
  Future<void> togglePolicy(LeaveType type) async {
    await dio.post('/leave/policies/${type.name}/toggle');
  }

  // ==========================================
  // Leave Balances (HR)
  // ==========================================

  @override
  Future<Map<String, dynamic>> getBalancesAdmin({
    required int page,
    required int limit,
    String? employeeId,
    String? department,
    String? branchId,
    int? year,
  }) async {
    final queryParameters = {
      'page': page,
      'limit': limit,
      if (employeeId != null) 'employeeId': employeeId,
      if (department != null) 'department': department,
      if (branchId != null) 'branchId': branchId,
      if (year != null) 'year': year,
    };
    final response = await dio.get('/leave/balances/admin', queryParameters: queryParameters);
    final data = response.data as Map<String, dynamic>;
    return {
      'total': data['total'],
      'page': data['page'],
      'limit': data['limit'],
      'totalPages': data['totalPages'],
      'items': (data['items'] as List).map((e) => LeaveBalance.fromJson(e)).toList(),
    };
  }

  @override
  Future<void> createBalance({
    required String userId,
    required LeaveType type,
    required int year,
    required double entitledDays,
  }) async {
    await dio.post('/leave/balances', data: {
      'userId': userId,
      'type': type.name,
      'year': year,
      'entitledDays': entitledDays,
    });
  }

  @override
  Future<void> adjustBalance({
    required String balanceId,
    required double adjustmentDays,
    required String reason,
  }) async {
    await dio.post('/leave/balances/$balanceId/adjust', data: {
      'adjustmentDays': adjustmentDays,
      'reason': reason,
    });
  }

  // ==========================================
  // Company Configurations
  // ==========================================

  @override
  Future<Map<String, dynamic>> getCompanyApprovalConfig() async {
    final response = await dio.get('/leave/config');
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<void> updateCompanyApprovalConfig(String? finalHrApproverId) async {
    await dio.post('/leave/config', data: {
      'finalHrApproverId': finalHrApproverId,
    });
  }

  // ==========================================
  // Employee Preflight Preview
  // ==========================================

  @override
  Future<Map<String, dynamic>> previewLeave({
    required LeaveType type,
    required DateTime startDate,
    required DateTime endDate,
    required bool isHalfDay,
    String? halfDayPeriod,
    required String reason,
  }) async {
    final response = await dio.post('/leave/preview', data: {
      'type': type.name,
      'startDate': _formatDate(startDate),
      'endDate': _formatDate(endDate),
      'isHalfDay': isHalfDay,
      'halfDayPeriod': halfDayPeriod,
      'reason': reason,
    });
    return response.data as Map<String, dynamic>;
  }
}
