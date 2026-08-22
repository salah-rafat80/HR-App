import 'package:hr_app_demo/core/utils/safe_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hr_app_demo/core/di/injection.dart';
import 'package:uuid/uuid.dart';
import 'package:hr_core/core/utils/leave_error_mapper.dart';
import 'leave_state.dart';
import 'package:hr_core/features/leave/domain/repositories/leave_repository.dart';
import 'package:hr_core/features/leave/domain/entities/leave_request.dart';
import 'package:hr_core/features/leave/domain/entities/leave_enums.dart';

import 'package:socket_io_client/socket_io_client.dart' as io;

class LeaveCubit extends SafeCubit<LeaveState> {
  final LeaveRepository _repository;
  final io.Socket _socket;

  LeaveCubit(this._repository, this._socket) : super(LeaveInitial()) {
    final prefs = getIt<SharedPreferences>();
    final userId = prefs.getString('user_id') ?? '';
    _socket.on('entity.updated.$userId', _onEntityUpdated);
  }

  void _onEntityUpdated(data) {
    if (data['entity'] == 'LeaveRequest' && !isClosed) {
      loadData();
    }
  }

  @override
  Future<void> close() {
    final prefs = getIt<SharedPreferences>();
    final userId = prefs.getString('user_id') ?? '';
    _socket.off('entity.updated.$userId', _onEntityUpdated);
    return super.close();
  }

  Future<void> loadData() async {
    if (!isClosed) {
      emit(LeaveLoading());
    }
    try {
      final balances = await _repository.getBalances();
      final requests = await _repository.getMyRequests();
      final calendar = await _repository.getTeamCalendar();
      final policies = await _repository.getPolicies();
      if (!isClosed) {
        emit(LeaveLoaded(
          balances: balances,
          requests: requests,
          teamCalendar: calendar,
          policies: policies,
        ));
      }
    } catch (e) {
      if (!isClosed) {
        emit(LeaveError(LeaveErrorMapper.map(e)));
      }
    }
  }

  Future<void> applyLeave({
    required LeaveType type,
    required DateTime start,
    required DateTime end,
    required bool isHalfDay,
    String? halfDayPeriod,
    required String reason,
  }) async {
    if (state is! LeaveLoaded) return;
    final currentState = state as LeaveLoaded;

    if (!isClosed) {
      emit(currentState.copyWith(isApplying: true, applyError: null, applySuccess: false));
    }
    try {
      final request = LeaveRequest(
        id: const Uuid().v4(),
        type: type,
        startDate: start,
        endDate: end,
        isHalfDay: isHalfDay,
        halfDayPeriod: halfDayPeriod,
        reason: reason,
        hasAttachment: false, // Attachment removed completely from production paths
        overallStatus: LeaveStatus.pending,
        approvalSteps: const [], // Backend resolves expected approvers on submission
      );
      await _repository.applyLeave(request);
      final newBalances = await _repository.getBalances();
      final newRequests = await _repository.getMyRequests();
      if (!isClosed) {
        emit(currentState.copyWith(
          isApplying: false,
          applySuccess: true,
          balances: newBalances,
          requests: newRequests,
        ));
      }
    } catch (e) {
      if (!isClosed) {
        emit(currentState.copyWith(
          isApplying: false,
          applyError: LeaveErrorMapper.map(e),
        ));
      }
    }
  }

  Future<Map<String, dynamic>> previewLeave({
    required LeaveType type,
    required DateTime startDate,
    required DateTime endDate,
    required bool isHalfDay,
    String? halfDayPeriod,
    required String reason,
  }) async {
    try {
      return await _repository.previewLeave(
        type: type,
        startDate: startDate,
        endDate: endDate,
        isHalfDay: isHalfDay,
        halfDayPeriod: halfDayPeriod,
        reason: reason,
      );
    } catch (e) {
      return {
        'error': LeaveErrorMapper.map(e),
      };
    }
  }

  Future<void> cancelRequestWithReason(String requestId, String reason) async {
    if (state is! LeaveLoaded) return;
    final currentState = state as LeaveLoaded;
    try {
      await _repository.cancelRequestWithReason(requestId, reason);
      final newRequests = await _repository.getMyRequests();
      final newBalances = await _repository.getBalances();
      if (!isClosed) {
        emit(currentState.copyWith(
          requests: newRequests,
          balances: newBalances,
        ));
      }
    } catch (e) {
      if (!isClosed) {
        emit(currentState.copyWith(
          applyError: LeaveErrorMapper.map(e),
        ));
      }
    }
  }

  Future<void> advanceApprovalStep(String requestId) async {
    if (state is! LeaveLoaded) return;
    try {
      await _repository.advanceApprovalStep(requestId);
      final newRequests = await _repository.getMyRequests();
      if (!isClosed) {
        emit((state as LeaveLoaded).copyWith(requests: newRequests));
      }
    } catch (e) {
      // ignore
    }
  }
}
