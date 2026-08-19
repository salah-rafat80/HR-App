import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hr_core/features/leave/domain/repositories/leave_repository.dart';
import 'package:hr_core/features/leave/domain/entities/leave_policy.dart';
import 'package:hr_core/features/leave/domain/entities/leave_balance.dart';
import 'package:hr_core/features/leave/domain/entities/leave_request.dart';
import 'package:hr_core/features/leave/domain/entities/leave_enums.dart';
import 'package:hr_core/core/enums/role_enums.dart';

// States
sealed class LeaveManagementState extends Equatable {
  const LeaveManagementState();
  @override
  List<Object?> get props => [];
}

class LeaveManagementInitial extends LeaveManagementState {}

class LeaveManagementLoading extends LeaveManagementState {}

class LeaveManagementLoaded extends LeaveManagementState {
  final List<LeavePolicy> policies;
  final List<LeaveBalance> balances;
  final List<LeaveRequest> pendingRequests;
  final Map<String, dynamic> config;
  final int totalBalances;
  final int currentBalancesPage;
  final int totalBalancesPages;
  final bool isSubmitting;
  final String? error;
  final bool success;

  const LeaveManagementLoaded({
    required this.policies,
    required this.balances,
    required this.pendingRequests,
    required this.config,
    required this.totalBalances,
    required this.currentBalancesPage,
    required this.totalBalancesPages,
    this.isSubmitting = false,
    this.error,
    this.success = false,
  });

  LeaveManagementLoaded copyWith({
    List<LeavePolicy>? policies,
    List<LeaveBalance>? balances,
    List<LeaveRequest>? pendingRequests,
    Map<String, dynamic>? config,
    int? totalBalances,
    int? currentBalancesPage,
    int? totalBalancesPages,
    bool? isSubmitting,
    String? error,
    bool? success,
  }) {
    return LeaveManagementLoaded(
      policies: policies ?? this.policies,
      balances: balances ?? this.balances,
      pendingRequests: pendingRequests ?? this.pendingRequests,
      config: config ?? this.config,
      totalBalances: totalBalances ?? this.totalBalances,
      currentBalancesPage: currentBalancesPage ?? this.currentBalancesPage,
      totalBalancesPages: totalBalancesPages ?? this.totalBalancesPages,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
      success: success ?? this.success,
    );
  }

  @override
  List<Object?> get props => [
        policies,
        balances,
        pendingRequests,
        config,
        totalBalances,
        currentBalancesPage,
        totalBalancesPages,
        isSubmitting,
        error,
        success,
      ];
}

class LeaveManagementError extends LeaveManagementState {
  final String message;
  const LeaveManagementError(this.message);
  @override
  List<Object?> get props => [message];
}

// Cubit
class LeaveManagementCubit extends Cubit<LeaveManagementState> {
  final LeaveRepository _repository;

  LeaveManagementCubit(this._repository) : super(LeaveManagementInitial());

  Future<void> loadDashboard({
    int page = 1,
    int limit = 10,
    String? employeeId,
    String? department,
    String? branchId,
    int? year,
  }) async {
    emit(LeaveManagementLoading());
    try {
      final policies = await _repository.getPolicies();
      final config = await _repository.getCompanyApprovalConfig();

      // Get pending approvals for Scope All
      final pending = await _repository.getPendingApprovals(ApprovalScope.all);

      final balancesRes = await _repository.getBalancesAdmin(
        page: page,
        limit: limit,
        employeeId: employeeId,
        department: department,
        branchId: branchId,
        year: year,
      );

      emit(LeaveManagementLoaded(
        policies: policies,
        balances: balancesRes['items'] as List<LeaveBalance>,
        pendingRequests: pending,
        config: config,
        totalBalances: balancesRes['total'] as int? ?? 0,
        currentBalancesPage: page,
        totalBalancesPages: balancesRes['totalPages'] as int? ?? 1,
      ));
    } catch (e) {
      emit(LeaveManagementError(e.toString()));
    }
  }

  Future<void> createPolicy(LeavePolicy policy) async {
    if (state is! LeaveManagementLoaded) return;
    final curr = state as LeaveManagementLoaded;
    emit(curr.copyWith(isSubmitting: true, error: null, success: false));

    try {
      await _repository.createPolicy(policy);
      final policies = await _repository.getPolicies();
      emit(curr.copyWith(policies: policies, isSubmitting: false, success: true));
    } catch (e) {
      emit(curr.copyWith(isSubmitting: false, error: e.toString()));
    }
  }

  Future<void> updatePolicy(LeaveType type, Map<String, dynamic> data) async {
    if (state is! LeaveManagementLoaded) return;
    final curr = state as LeaveManagementLoaded;
    emit(curr.copyWith(isSubmitting: true, error: null, success: false));

    try {
      await _repository.updatePolicy(type, data);
      final policies = await _repository.getPolicies();
      emit(curr.copyWith(policies: policies, isSubmitting: false, success: true));
    } catch (e) {
      emit(curr.copyWith(isSubmitting: false, error: e.toString()));
    }
  }

  Future<void> togglePolicy(LeaveType type) async {
    if (state is! LeaveManagementLoaded) return;
    final curr = state as LeaveManagementLoaded;
    emit(curr.copyWith(isSubmitting: true, error: null, success: false));

    try {
      await _repository.togglePolicy(type);
      final policies = await _repository.getPolicies();
      emit(curr.copyWith(policies: policies, isSubmitting: false, success: true));
    } catch (e) {
      emit(curr.copyWith(isSubmitting: false, error: e.toString()));
    }
  }

  Future<void> createBalance({
    required String userId,
    required LeaveType type,
    required int year,
    required double entitledDays,
  }) async {
    if (state is! LeaveManagementLoaded) return;
    final curr = state as LeaveManagementLoaded;
    emit(curr.copyWith(isSubmitting: true, error: null, success: false));

    try {
      await _repository.createBalance(
        userId: userId,
        type: type,
        year: year,
        entitledDays: entitledDays,
      );
      // Reload current page
      await loadDashboard(
        page: curr.currentBalancesPage,
      );
    } catch (e) {
      emit(curr.copyWith(isSubmitting: false, error: e.toString()));
    }
  }

  Future<void> adjustBalance({
    required String balanceId,
    required double adjustmentDays,
    required String reason,
  }) async {
    if (state is! LeaveManagementLoaded) return;
    final curr = state as LeaveManagementLoaded;
    emit(curr.copyWith(isSubmitting: true, error: null, success: false));

    try {
      await _repository.adjustBalance(
        balanceId: balanceId,
        adjustmentDays: adjustmentDays,
        reason: reason,
      );
      await loadDashboard(
        page: curr.currentBalancesPage,
      );
    } catch (e) {
      emit(curr.copyWith(isSubmitting: false, error: e.toString()));
    }
  }

  Future<void> updateCompanyApprovalConfig(String? finalHrApproverId) async {
    if (state is! LeaveManagementLoaded) return;
    final curr = state as LeaveManagementLoaded;
    emit(curr.copyWith(isSubmitting: true, error: null, success: false));

    try {
      await _repository.updateCompanyApprovalConfig(finalHrApproverId);
      final config = await _repository.getCompanyApprovalConfig();
      emit(curr.copyWith(config: config, isSubmitting: false, success: true));
    } catch (e) {
      emit(curr.copyWith(isSubmitting: false, error: e.toString()));
    }
  }

  Future<void> approveRequest(String requestId, String? comment) async {
    if (state is! LeaveManagementLoaded) return;
    final curr = state as LeaveManagementLoaded;
    try {
      await _repository.approveRequestWithComment(requestId, comment);
      await loadDashboard(page: curr.currentBalancesPage);
    } catch (e) {
      emit(curr.copyWith(error: e.toString()));
    }
  }

  Future<void> rejectRequest(String requestId, String comment) async {
    if (state is! LeaveManagementLoaded) return;
    final curr = state as LeaveManagementLoaded;
    try {
      await _repository.rejectRequestWithComment(requestId, comment);
      await loadDashboard(page: curr.currentBalancesPage);
    } catch (e) {
      emit(curr.copyWith(error: e.toString()));
    }
  }

  Future<void> cancelRequest(String requestId, String reason) async {
    if (state is! LeaveManagementLoaded) return;
    final curr = state as LeaveManagementLoaded;
    try {
      await _repository.cancelRequestWithReason(requestId, reason);
      await loadDashboard(page: curr.currentBalancesPage);
    } catch (e) {
      emit(curr.copyWith(error: e.toString()));
    }
  }
}
