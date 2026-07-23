import 'package:dio/dio.dart';
import '../../domain/entities/leave_balance.dart';
import '../../domain/entities/leave_enums.dart';
import '../../domain/entities/leave_request.dart';
import '../../domain/entities/team_leave_entry.dart';
import '../../../../core/enums/role_enums.dart';
import '../../domain/repositories/leave_repository.dart';

class ApiLeaveRepositoryImpl implements LeaveRepository {
  final Dio dio;

  ApiLeaveRepositoryImpl({required this.dio});

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
    await dio.post('/leave/apply', data: draft.toJson());
  }

  @override
  Future<void> cancelRequest(String id) async {
    await dio.delete('/leave/$id');
  }

  @override
  Future<List<TeamLeaveEntry>> getTeamCalendar() async {
    final response = await dio.get('/leave/team-calendar');
    return (response.data as List).map((e) => TeamLeaveEntry.fromJson(e)).toList();
  }

  @override
  Future<void> requestEncashment(LeaveType type, int days) async {
    // Implement if needed in backend
    throw UnimplementedError('requestEncashment not implemented on API yet');
  }

  @override
  Future<void> advanceApprovalStep(String requestId) async {
    // The Nest backend has separate approve/reject endpoints, not advanceApprovalStep
    // This is probably called by a fake data source, but for API, we'll map it to approve
    await approveRequest(requestId);
  }

  @override
  Future<List<LeaveRequest>> getPendingApprovals(ApprovalScope scope) async {
    final response = await dio.get('/leave/pending');
    return (response.data as List).map((e) => LeaveRequest.fromJson(e)).toList();
  }

  @override
  Future<void> approveRequest(String requestId) async {
    await dio.post('/leave/$requestId/approve');
  }

  @override
  Future<void> rejectRequest(String requestId) async {
    await dio.post('/leave/$requestId/reject');
  }
}
