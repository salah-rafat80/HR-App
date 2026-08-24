import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hr_core/core/enums/role_enums.dart';
import 'package:hr_core/features/leave/domain/entities/leave_balance.dart';
import 'package:hr_core/features/leave/domain/entities/leave_request.dart';
import 'package:hr_core/features/leave/domain/repositories/leave_repository.dart';
import 'package:hr_core/features/communication/domain/entities/communication_entities.dart';
import 'package:hr_core/features/communication/domain/repositories/communication_repository.dart';
import 'package:hr_core/core/utils/leave_error_mapper.dart';

class DashboardState extends Equatable {
  final bool isLoading;
  final List<LeaveBalance> balances;
  final List<LeaveRequest> myRequests;
  final List<LeaveRequest> pendingApprovals;
  final List<Announcement> announcements;
  final String? errorMessage;

  const DashboardState({
    required this.isLoading,
    required this.balances,
    required this.myRequests,
    required this.pendingApprovals,
    required this.announcements,
    this.errorMessage,
  });

  factory DashboardState.initial() {
    return const DashboardState(
      isLoading: false,
      balances: [],
      myRequests: [],
      pendingApprovals: [],
      announcements: [],
      errorMessage: null,
    );
  }

  DashboardState copyWith({
    bool? isLoading,
    List<LeaveBalance>? balances,
    List<LeaveRequest>? myRequests,
    List<LeaveRequest>? pendingApprovals,
    List<Announcement>? announcements,
    String? errorMessage,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      balances: balances ?? this.balances,
      myRequests: myRequests ?? this.myRequests,
      pendingApprovals: pendingApprovals ?? this.pendingApprovals,
      announcements: announcements ?? this.announcements,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        balances,
        myRequests,
        pendingApprovals,
        announcements,
        errorMessage,
      ];
}

class DashboardCubit extends Cubit<DashboardState> {
  final LeaveRepository _leaveRepo;
  final CommunicationRepository _commRepo;

  DashboardCubit(this._leaveRepo, this._commRepo)
      : super(DashboardState.initial());

  Future<void> loadDashboard(UserRole role) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      List<LeaveBalance> balances = [];
      List<LeaveRequest> myRequests = [];
      List<LeaveRequest> pendingApprovals = [];
      List<Announcement> announcements = [];

      try {
        announcements = await _commRepo.getAnnouncements();
      } catch (_) {}

      if (role == UserRole.employee) {
        balances = await _leaveRepo.getBalances();
        myRequests = await _leaveRepo.getMyRequests();
      } else {
        pendingApprovals = await _leaveRepo.getPendingApprovals(
          ApprovalScope.all,
        );
        try {
          balances = await _leaveRepo.getBalances();
          myRequests = await _leaveRepo.getMyRequests();
        } catch (_) {}
      }

      emit(
        DashboardState(
          isLoading: false,
          balances: balances,
          myRequests: myRequests,
          pendingApprovals: pendingApprovals,
          announcements: announcements,
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: LeaveErrorMapper.map(e),
        ),
      );
    }
  }

  Future<void> createAnnouncement(
    String title,
    String body, {
    String? department,
  }) async {
    try {
      await _commRepo.createAnnouncement(title, body, department: department);
      final announcements = await _commRepo.getAnnouncements();
      emit(state.copyWith(announcements: announcements));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }
}
