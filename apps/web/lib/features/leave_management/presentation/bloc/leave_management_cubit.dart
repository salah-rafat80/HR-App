import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hr_core/features/leave/domain/repositories/leave_repository.dart';
import 'package:hr_core/features/leave/domain/entities/leave_policy.dart';
import 'package:hr_core/features/leave/domain/entities/leave_balance.dart';
import 'package:hr_core/features/leave/domain/entities/leave_request.dart';
import 'package:hr_core/features/leave/domain/entities/leave_enums.dart';
import 'package:hr_core/core/enums/role_enums.dart';
import 'package:hr_core/core/utils/leave_error_mapper.dart';

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
  final String? policiesError;

  final List<LeaveBalance> balances;
  final String? balancesError;

  final List<LeaveRequest> pendingRequests;
  final String? pendingRequestsError;

  final Map<String, dynamic> config;
  final String? configError;

  final List<Map<String, dynamic>> employees;
  final String? employeesError;

  final int totalBalances;
  final int currentBalancesPage;
  final int totalBalancesPages;
  final bool isSubmitting;
  final String? actionError;
  final bool success;

  const LeaveManagementLoaded({
    required this.policies,
    this.policiesError,
    required this.balances,
    this.balancesError,
    required this.pendingRequests,
    this.pendingRequestsError,
    required this.config,
    this.configError,
    required this.employees,
    this.employeesError,
    required this.totalBalances,
    required this.currentBalancesPage,
    required this.totalBalancesPages,
    this.isSubmitting = false,
    this.actionError,
    this.success = false,
  });

  LeaveManagementLoaded copyWith({
    List<LeavePolicy>? policies,
    Object? policiesError = _sentinel,
    List<LeaveBalance>? balances,
    Object? balancesError = _sentinel,
    List<LeaveRequest>? pendingRequests,
    Object? pendingRequestsError = _sentinel,
    Map<String, dynamic>? config,
    Object? configError = _sentinel,
    List<Map<String, dynamic>>? employees,
    Object? employeesError = _sentinel,
    int? totalBalances,
    int? currentBalancesPage,
    int? totalBalancesPages,
    bool? isSubmitting,
    Object? actionError = _sentinel,
    bool? success,
  }) {
    return LeaveManagementLoaded(
      policies: policies ?? this.policies,
      policiesError: policiesError == _sentinel
          ? this.policiesError
          : policiesError as String?,
      balances: balances ?? this.balances,
      balancesError: balancesError == _sentinel
          ? this.balancesError
          : balancesError as String?,
      pendingRequests: pendingRequests ?? this.pendingRequests,
      pendingRequestsError: pendingRequestsError == _sentinel
          ? this.pendingRequestsError
          : pendingRequestsError as String?,
      config: config ?? this.config,
      configError: configError == _sentinel
          ? this.configError
          : configError as String?,
      employees: employees ?? this.employees,
      employeesError: employeesError == _sentinel
          ? this.employeesError
          : employeesError as String?,
      totalBalances: totalBalances ?? this.totalBalances,
      currentBalancesPage: currentBalancesPage ?? this.currentBalancesPage,
      totalBalancesPages: totalBalancesPages ?? this.totalBalancesPages,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      actionError: actionError == _sentinel
          ? this.actionError
          : actionError as String?,
      success: success ?? this.success,
    );
  }

  @override
  List<Object?> get props => [
    policies,
    policiesError,
    balances,
    balancesError,
    pendingRequests,
    pendingRequestsError,
    config,
    configError,
    employees,
    employeesError,
    totalBalances,
    currentBalancesPage,
    totalBalancesPages,
    isSubmitting,
    actionError,
    success,
  ];
}

const _sentinel = Object();

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

    List<LeavePolicy>? policies;
    String? policiesErr;

    Map<String, dynamic>? config;
    String? configErr;

    List<LeaveRequest>? pending;
    String? pendingErr;

    List<LeaveBalance>? balances;
    int totalBal = 0;
    int totalBalPages = 1;
    String? balancesErr;

    List<Map<String, dynamic>>? employees;
    String? employeesErr;

    await Future.wait([
      Future(() async {
        try {
          policies = await _repository.getPolicies();
        } catch (e) {
          policiesErr = LeaveErrorMapper.map(e);
        }
      }),
      Future(() async {
        try {
          config = await _repository.getCompanyApprovalConfig();
        } catch (e) {
          configErr = LeaveErrorMapper.map(e);
        }
      }),
      Future(() async {
        try {
          pending = await _repository.getPendingApprovals(ApprovalScope.all);
        } catch (e) {
          pendingErr = LeaveErrorMapper.map(e);
        }
      }),
      Future(() async {
        try {
          final res = await _repository.getBalancesAdmin(
            page: page,
            limit: limit,
            employeeId: employeeId,
            department: department,
            branchId: branchId,
            year: year,
          );
          final rawItems = res['items'];
          balances = rawItems is List
              ? rawItems.whereType<LeaveBalance>().toList()
              : <LeaveBalance>[];
          totalBal = res['total'] as int? ?? 0;
          totalBalPages = res['totalPages'] as int? ?? 1;
        } catch (e) {
          balancesErr = LeaveErrorMapper.map(e);
        }
      }),
      Future(() async {
        try {
          employees = await _repository.getEmployeesForPicker();
        } catch (e) {
          employeesErr = LeaveErrorMapper.map(e);
        }
      }),
    ]);

    emit(
      LeaveManagementLoaded(
        policies: policies ?? [],
        policiesError: policiesErr,
        balances: balances ?? [],
        balancesError: balancesErr,
        pendingRequests: pending ?? [],
        pendingRequestsError: pendingErr,
        config: config ?? {'configured': false},
        configError: configErr,
        employees: employees ?? [],
        employeesError: employeesErr,
        totalBalances: totalBal,
        currentBalancesPage: page,
        totalBalancesPages: totalBalPages,
      ),
    );
  }

  Future<void> refreshPolicies() async {
    if (state is! LeaveManagementLoaded) return;
    final curr = state as LeaveManagementLoaded;
    try {
      final policies = await _repository.getPolicies();
      emit(curr.copyWith(policies: policies, policiesError: null));
    } catch (e) {
      emit(curr.copyWith(policiesError: LeaveErrorMapper.map(e)));
    }
  }

  Future<void> refreshBalances({
    int page = 1,
    int limit = 10,
    String? employeeId,
    String? department,
    String? branchId,
    int? year,
  }) async {
    if (state is! LeaveManagementLoaded) return;
    final curr = state as LeaveManagementLoaded;

    try {
      final res = await _repository.getBalancesAdmin(
        page: page,
        limit: limit,
        employeeId: employeeId,
        department: department,
        branchId: branchId,
        year: year,
      );
      final rawItems = res['items'];
      final list = rawItems is List
          ? rawItems.whereType<LeaveBalance>().toList()
          : <LeaveBalance>[];
      emit(
        curr.copyWith(
          balances: list,
          balancesError: null,
          totalBalances: res['total'] as int? ?? 0,
          currentBalancesPage: page,
          totalBalancesPages: res['totalPages'] as int? ?? 1,
          isSubmitting: false,
          actionError: null,
        ),
      );
    } catch (e) {
      emit(
        curr.copyWith(
          balancesError: LeaveErrorMapper.map(e),
          isSubmitting: false,
        ),
      );
    }
  }

  Future<void> refreshPendingRequests() async {
    if (state is! LeaveManagementLoaded) return;
    final curr = state as LeaveManagementLoaded;
    try {
      final pending = await _repository.getPendingApprovals(ApprovalScope.all);
      emit(curr.copyWith(pendingRequests: pending, pendingRequestsError: null));
    } catch (e) {
      emit(curr.copyWith(pendingRequestsError: LeaveErrorMapper.map(e)));
    }
  }

  Future<void> refreshEmployees() async {
    if (state is! LeaveManagementLoaded) return;
    final curr = state as LeaveManagementLoaded;
    try {
      final employees = await _repository.getEmployeesForPicker();
      emit(curr.copyWith(employees: employees, employeesError: null));
    } catch (e) {
      emit(curr.copyWith(employeesError: LeaveErrorMapper.map(e)));
    }
  }

  Future<bool> createPolicy(LeavePolicy policy) async {
    if (state is! LeaveManagementLoaded) return false;
    final curr = state as LeaveManagementLoaded;
    emit(curr.copyWith(isSubmitting: true, actionError: null, success: false));

    try {
      await _repository.createPolicy(policy);
      final policies = await _repository.getPolicies();
      emit(
        curr.copyWith(
          policies: policies,
          policiesError: null,
          isSubmitting: false,
          success: true,
        ),
      );
      return true;
    } catch (e) {
      final err = LeaveErrorMapper.map(e);
      emit(curr.copyWith(isSubmitting: false, actionError: err));
      return false;
    }
  }

  Future<bool> updatePolicy(LeaveType type, Map<String, dynamic> data) async {
    if (state is! LeaveManagementLoaded) return false;
    final curr = state as LeaveManagementLoaded;
    emit(curr.copyWith(isSubmitting: true, actionError: null, success: false));

    try {
      await _repository.updatePolicy(type, data);
      final policies = await _repository.getPolicies();
      emit(
        curr.copyWith(
          policies: policies,
          policiesError: null,
          isSubmitting: false,
          success: true,
        ),
      );
      return true;
    } catch (e) {
      final err = LeaveErrorMapper.map(e);
      emit(curr.copyWith(isSubmitting: false, actionError: err));
      return false;
    }
  }

  Future<bool> togglePolicy(LeaveType type) async {
    if (state is! LeaveManagementLoaded) return false;
    final curr = state as LeaveManagementLoaded;
    emit(curr.copyWith(isSubmitting: true, actionError: null, success: false));

    try {
      await _repository.togglePolicy(type);
      final policies = await _repository.getPolicies();
      emit(
        curr.copyWith(
          policies: policies,
          policiesError: null,
          isSubmitting: false,
          success: true,
        ),
      );
      return true;
    } catch (e) {
      final err = LeaveErrorMapper.map(e);
      emit(curr.copyWith(isSubmitting: false, actionError: err));
      return false;
    }
  }

  Future<bool> createBalance({
    required String userId,
    required LeaveType type,
    required int year,
    required double entitledDays,
  }) async {
    if (state is! LeaveManagementLoaded) return false;
    final curr = state as LeaveManagementLoaded;
    emit(curr.copyWith(isSubmitting: true, actionError: null, success: false));

    try {
      await _repository.createBalance(
        userId: userId,
        type: type,
        year: year,
        entitledDays: entitledDays,
      );
      await refreshBalances(page: curr.currentBalancesPage, year: year);
      return true;
    } catch (e) {
      final err = LeaveErrorMapper.map(e);
      emit(curr.copyWith(isSubmitting: false, actionError: err));
      return false;
    }
  }

  Future<bool> adjustBalance({
    required String balanceId,
    required double adjustmentDays,
    required String reason,
  }) async {
    if (state is! LeaveManagementLoaded) return false;
    final curr = state as LeaveManagementLoaded;
    emit(curr.copyWith(isSubmitting: true, actionError: null, success: false));

    try {
      await _repository.adjustBalance(
        balanceId: balanceId,
        adjustmentDays: adjustmentDays,
        reason: reason,
      );
      await refreshBalances(page: curr.currentBalancesPage);
      return true;
    } catch (e) {
      final err = LeaveErrorMapper.map(e);
      emit(curr.copyWith(isSubmitting: false, actionError: err));
      return false;
    }
  }

  Future<bool> updateCompanyApprovalConfig(String? finalHrApproverId) async {
    if (state is! LeaveManagementLoaded) return false;
    final curr = state as LeaveManagementLoaded;
    emit(curr.copyWith(isSubmitting: true, actionError: null, success: false));

    try {
      await _repository.updateCompanyApprovalConfig(finalHrApproverId);
      final config = await _repository.getCompanyApprovalConfig();
      emit(
        curr.copyWith(
          config: config,
          configError: null,
          isSubmitting: false,
          success: true,
        ),
      );
      return true;
    } catch (e) {
      final err = LeaveErrorMapper.map(e);
      emit(curr.copyWith(isSubmitting: false, actionError: err));
      return false;
    }
  }

  Future<bool> approveRequest(String requestId, String? comment) async {
    if (state is! LeaveManagementLoaded) return false;
    final curr = state as LeaveManagementLoaded;
    emit(curr.copyWith(isSubmitting: true, actionError: null, success: false));
    try {
      await _repository.approveRequestWithComment(requestId, comment);
      final pending = await _repository.getPendingApprovals(ApprovalScope.all);
      emit(
        curr.copyWith(
          pendingRequests: pending,
          pendingRequestsError: null,
          isSubmitting: false,
          success: true,
        ),
      );
      return true;
    } catch (e) {
      final err = LeaveErrorMapper.map(e);
      emit(curr.copyWith(isSubmitting: false, actionError: err));
      return false;
    }
  }

  Future<bool> rejectRequest(String requestId, String comment) async {
    if (state is! LeaveManagementLoaded) return false;
    final curr = state as LeaveManagementLoaded;
    emit(curr.copyWith(isSubmitting: true, actionError: null, success: false));
    try {
      await _repository.rejectRequestWithComment(requestId, comment);
      final pending = await _repository.getPendingApprovals(ApprovalScope.all);
      emit(
        curr.copyWith(
          pendingRequests: pending,
          pendingRequestsError: null,
          isSubmitting: false,
          success: true,
        ),
      );
      return true;
    } catch (e) {
      final err = LeaveErrorMapper.map(e);
      emit(curr.copyWith(isSubmitting: false, actionError: err));
      return false;
    }
  }

  Future<bool> cancelRequest(String requestId, String reason) async {
    if (state is! LeaveManagementLoaded) return false;
    final curr = state as LeaveManagementLoaded;
    emit(curr.copyWith(isSubmitting: true, actionError: null, success: false));
    try {
      await _repository.cancelRequestWithReason(requestId, reason);
      final pending = await _repository.getPendingApprovals(ApprovalScope.all);
      emit(
        curr.copyWith(
          pendingRequests: pending,
          pendingRequestsError: null,
          isSubmitting: false,
          success: true,
        ),
      );
      return true;
    } catch (e) {
      final err = LeaveErrorMapper.map(e);
      emit(curr.copyWith(isSubmitting: false, actionError: err));
      return false;
    }
  }
}
