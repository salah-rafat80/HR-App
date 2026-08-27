import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hr_core/core/enums/role_enums.dart';
import 'package:hr_core/features/leave/domain/entities/leave_balance.dart';
import 'package:hr_core/features/leave/domain/entities/leave_request.dart';
import 'package:hr_core/features/leave/domain/repositories/leave_repository.dart';
import 'package:hr_core/features/communication/domain/entities/communication_entities.dart';
import 'package:hr_core/features/communication/domain/repositories/announcement_repository.dart';
import 'package:hr_core/core/utils/leave_error_mapper.dart';

class DashboardState extends Equatable {
  final bool isLoading;
  final List<LeaveBalance> balances;
  final List<LeaveRequest> myRequests;
  final List<LeaveRequest> pendingApprovals;
  final List<Announcement> announcements;
  final String? errorMessage;
  final String? announcementsError;

  const DashboardState({
    required this.isLoading,
    required this.balances,
    required this.myRequests,
    required this.pendingApprovals,
    required this.announcements,
    this.errorMessage,
    this.announcementsError,
  });

  factory DashboardState.initial() {
    return const DashboardState(
      isLoading: false,
      balances: [],
      myRequests: [],
      pendingApprovals: [],
      announcements: [],
      errorMessage: null,
      announcementsError: null,
    );
  }

  DashboardState copyWith({
    bool? isLoading,
    List<LeaveBalance>? balances,
    List<LeaveRequest>? myRequests,
    List<LeaveRequest>? pendingApprovals,
    List<Announcement>? announcements,
    String? errorMessage,
    String? announcementsError,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      balances: balances ?? this.balances,
      myRequests: myRequests ?? this.myRequests,
      pendingApprovals: pendingApprovals ?? this.pendingApprovals,
      announcements: announcements ?? this.announcements,
      errorMessage: errorMessage,
      announcementsError: announcementsError,
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
        announcementsError,
      ];
}

class DashboardCubit extends Cubit<DashboardState> {
  final LeaveRepository _leaveRepo;
  final AnnouncementRepository _announcementRepo;

  DashboardCubit(this._leaveRepo, this._announcementRepo)
      : super(DashboardState.initial());

  Future<void> loadDashboard(UserRole role) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      List<LeaveBalance> balances = [];
      List<LeaveRequest> myRequests = [];
      List<LeaveRequest> pendingApprovals = [];
      List<Announcement> announcements = state.announcements;
      String? announcementsError;

      try {
        announcements = await _announcementRepo.getAnnouncements();
      } catch (e) {
        announcementsError = 'error_communication_failed';
      }

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
          announcementsError: announcementsError,
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

  Future<void> loadAnnouncementsOnly() async {
    try {
      final announcements = await _announcementRepo.getAnnouncements();
      emit(state.copyWith(announcements: announcements, announcementsError: null));
    } catch (e) {
      emit(state.copyWith(announcementsError: 'error_communication_failed'));
    }
  }

  Future<void> createAnnouncement(
    String title,
    String body,
  ) async {
    try {
      final newAnnouncement = await _announcementRepo.createAnnouncement(title, body);
      emit(state.copyWith(
        announcements: [newAnnouncement, ...state.announcements],
      ));

      try {
        await loadAnnouncementsOnly();
      } catch (_) {}
    } catch (e) {
      rethrow;
    }
  }
}
