import 'package:hr_app_demo/core/utils/safe_cubit.dart';
import 'package:uuid/uuid.dart';
import 'leave_state.dart';
import 'package:hr_core/features/leave/domain/repositories/leave_repository.dart';
import 'package:hr_core/features/leave/domain/entities/leave_request.dart';
import 'package:hr_core/features/leave/domain/entities/leave_enums.dart';

class LeaveCubit extends SafeCubit<LeaveState> {
  final LeaveRepository _repository;

  LeaveCubit(this._repository) : super(LeaveInitial());

  Future<void> loadData() async {
    if (!isClosed) { emit(LeaveLoading()); }
    try {
      final balances = await _repository.getBalances();
      final requests = await _repository.getMyRequests();
      final calendar = await _repository.getTeamCalendar();
      if (!isClosed) { emit(LeaveLoaded(balances: balances, requests: requests, teamCalendar: calendar)); }
    } catch (e) {
      if (!isClosed) { emit(LeaveError(e.toString())); }
    }
  }

  Future<void> applyLeave(LeaveType type, DateTime start, DateTime end, bool isHalfDay, String? halfDayPeriod, String reason, bool hasAttachment) async {
    if (state is! LeaveLoaded) return;
    final currentState = state as LeaveLoaded;
    
    if (!isClosed) { emit(currentState.copyWith(isApplying: true, applyError: null, applySuccess: false)); }
    try {
      final request = LeaveRequest(
        id: const Uuid().v4(),
        type: type,
        startDate: start,
        endDate: end,
        isHalfDay: isHalfDay,
        halfDayPeriod: halfDayPeriod,
        reason: reason,
        hasAttachment: hasAttachment,
        overallStatus: LeaveStatus.pending,
        approvalSteps: [
          LeaveApprovalStep(stepName: 'submitted', status: LeaveStatus.approved, timestamp: DateTime.now()),
          LeaveApprovalStep(stepName: 'manager', status: LeaveStatus.pending, timestamp: DateTime.now()),
          LeaveApprovalStep(stepName: 'hr', status: LeaveStatus.pending, timestamp: DateTime.now()),
          LeaveApprovalStep(stepName: 'final_approval', status: LeaveStatus.pending, timestamp: DateTime.now()),
        ],
      );
      await _repository.applyLeave(request);
      final newBalances = await _repository.getBalances();
      final newRequests = await _repository.getMyRequests();
      if (!isClosed) { emit(currentState.copyWith(isApplying: false, applySuccess: true, balances: newBalances, requests: newRequests)); }
    } catch (e) {
      if (!isClosed) { emit(currentState.copyWith(isApplying: false, applyError: e.toString())); }
    }
  }

  Future<void> advanceApprovalStep(String requestId) async {
    if (state is! LeaveLoaded) return;
    try {
      await _repository.advanceApprovalStep(requestId);
      final newRequests = await _repository.getMyRequests();
      if (!isClosed) { emit((state as LeaveLoaded).copyWith(requests: newRequests)); }
    } catch (e) {
      // ignore
    }
  }
}
