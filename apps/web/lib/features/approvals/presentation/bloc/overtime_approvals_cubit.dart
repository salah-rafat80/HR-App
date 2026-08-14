import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hr_core/features/attendance/domain/entities/overtime_request.dart';
import 'package:hr_core/features/attendance/domain/repositories/attendance_repository.dart';

abstract class OvertimeApprovalsState extends Equatable {
  const OvertimeApprovalsState();
  @override
  List<Object?> get props => [];
}

class OvertimeApprovalsInitial extends OvertimeApprovalsState {}

class OvertimeApprovalsLoading extends OvertimeApprovalsState {}

class OvertimeApprovalsLoaded extends OvertimeApprovalsState {
  final List<OvertimeRequest> requests;

  const OvertimeApprovalsLoaded(this.requests);

  @override
  List<Object?> get props => [requests];
}

class OvertimeApprovalsActionProcessing extends OvertimeApprovalsState {
  final String requestId;
  final String actionType; // 'approve' or 'reject'

  const OvertimeApprovalsActionProcessing(this.requestId, this.actionType);

  @override
  List<Object?> get props => [requestId, actionType];
}

class OvertimeApprovalsActionSuccess extends OvertimeApprovalsState {
  final String message;

  const OvertimeApprovalsActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class OvertimeApprovalsError extends OvertimeApprovalsState {
  final String message;

  const OvertimeApprovalsError(this.message);

  @override
  List<Object?> get props => [message];
}

class OvertimeApprovalsCubit extends Cubit<OvertimeApprovalsState> {
  final AttendanceRepository repository;

  OvertimeApprovalsCubit(this.repository) : super(OvertimeApprovalsInitial());

  Future<void> loadPendingRequests() async {
    emit(OvertimeApprovalsLoading());
    try {
      final list = await repository.getPendingOvertimeApprovals();
      emit(OvertimeApprovalsLoaded(list));
    } catch (e) {
      emit(OvertimeApprovalsError(e.toString()));
    }
  }

  Future<void> approveRequest({
    required String requestId,
    required bool isHr,
    String? comment,
  }) async {
    emit(OvertimeApprovalsActionProcessing(requestId, 'approve'));
    try {
      if (isHr) {
        await repository.approveOvertimeAsHr(requestId, comment: comment);
      } else {
        await repository.approveOvertimeAsTeamLead(requestId, comment: comment);
      }
      emit(const OvertimeApprovalsActionSuccess('Overtime request approved successfully'));
      await loadPendingRequests();
    } catch (e) {
      emit(OvertimeApprovalsError('Approval failed: ${e.toString()}'));
      await loadPendingRequests();
    }
  }

  Future<void> rejectRequest({
    required String requestId,
    required bool isHr,
    String? comment,
  }) async {
    emit(OvertimeApprovalsActionProcessing(requestId, 'reject'));
    try {
      if (isHr) {
        await repository.rejectOvertimeAsHr(requestId, comment: comment);
      } else {
        await repository.rejectOvertimeAsTeamLead(requestId, comment: comment);
      }
      emit(const OvertimeApprovalsActionSuccess('Overtime request rejected successfully'));
      await loadPendingRequests();
    } catch (e) {
      emit(OvertimeApprovalsError('Rejection failed: ${e.toString()}'));
      await loadPendingRequests();
    }
  }
}
