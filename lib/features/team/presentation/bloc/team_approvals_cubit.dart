import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/enums/role_enums.dart';
import '../../../leave/domain/entities/leave_request.dart';
import '../../../leave/domain/repositories/leave_repository.dart';

abstract class TeamApprovalsState {}

class TeamApprovalsInitial extends TeamApprovalsState {}
class TeamApprovalsLoading extends TeamApprovalsState {}
class TeamApprovalsLoaded extends TeamApprovalsState {
  final List<LeaveRequest> requests;
  TeamApprovalsLoaded(this.requests);
}
class TeamApprovalsError extends TeamApprovalsState {
  final String message;
  TeamApprovalsError(this.message);
}

class TeamApprovalsCubit extends Cubit<TeamApprovalsState> {
  final LeaveRepository _leaveRepository;

  TeamApprovalsCubit(this._leaveRepository) : super(TeamApprovalsInitial());

  Future<void> fetchPendingApprovals(ApprovalScope scope) async {
    emit(TeamApprovalsLoading());
    try {
      final requests = await _leaveRepository.getPendingApprovals(scope);
      emit(TeamApprovalsLoaded(requests));
    } catch (e) {
      emit(TeamApprovalsError(e.toString()));
    }
  }

  Future<void> approveRequest(String id, ApprovalScope scope) async {
    try {
      await _leaveRepository.approveRequest(id);
      fetchPendingApprovals(scope);
    } catch (e) {
      emit(TeamApprovalsError(e.toString()));
    }
  }

  Future<void> rejectRequest(String id, ApprovalScope scope) async {
    try {
      await _leaveRepository.rejectRequest(id);
      fetchPendingApprovals(scope);
    } catch (e) {
      emit(TeamApprovalsError(e.toString()));
    }
  }
}
