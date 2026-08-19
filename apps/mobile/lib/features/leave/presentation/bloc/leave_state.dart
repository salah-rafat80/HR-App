import 'package:equatable/equatable.dart';
import 'package:hr_core/features/leave/domain/entities/leave_balance.dart';
import 'package:hr_core/features/leave/domain/entities/leave_request.dart';
import 'package:hr_core/features/leave/domain/entities/team_leave_entry.dart';
import 'package:hr_core/features/leave/domain/entities/leave_policy.dart';

sealed class LeaveState extends Equatable {
  const LeaveState();
  @override
  List<Object?> get props => [];
}

class LeaveInitial extends LeaveState {}

class LeaveLoading extends LeaveState {}

class LeaveLoaded extends LeaveState {
  final List<LeaveBalance> balances;
  final List<LeaveRequest> requests;
  final List<TeamLeaveEntry> teamCalendar;
  final List<LeavePolicy> policies;
  final bool isApplying;
  final String? applyError;
  final bool applySuccess;

  const LeaveLoaded({
    required this.balances,
    required this.requests,
    required this.teamCalendar,
    required this.policies,
    this.isApplying = false,
    this.applyError,
    this.applySuccess = false,
  });

  LeaveLoaded copyWith({
    List<LeaveBalance>? balances,
    List<LeaveRequest>? requests,
    List<TeamLeaveEntry>? teamCalendar,
    List<LeavePolicy>? policies,
    bool? isApplying,
    String? applyError,
    bool? applySuccess,
  }) {
    return LeaveLoaded(
      balances: balances ?? this.balances,
      requests: requests ?? this.requests,
      teamCalendar: teamCalendar ?? this.teamCalendar,
      policies: policies ?? this.policies,
      isApplying: isApplying ?? this.isApplying,
      applyError: applyError,
      applySuccess: applySuccess ?? this.applySuccess,
    );
  }

  @override
  List<Object?> get props => [balances, requests, teamCalendar, policies, isApplying, applyError, applySuccess];
}

class LeaveError extends LeaveState {
  final String message;
  const LeaveError(this.message);
  @override
  List<Object?> get props => [message];
}
