import 'package:equatable/equatable.dart';
import 'package:hr_core/features/attendance/domain/entities/attendance_record.dart';
import 'package:hr_core/features/attendance/domain/entities/overtime_request.dart';
import 'package:hr_core/features/attendance/domain/entities/shift_info.dart';

sealed class AttendanceState extends Equatable {
  const AttendanceState();

  @override
  List<Object?> get props => [];
}

class AttendanceInitial extends AttendanceState {}

class AttendanceLoading extends AttendanceState {}

class AttendanceLoaded extends AttendanceState {
  final AttendanceRecord todayStatus;
  final List<AttendanceRecord> history;
  final ShiftInfo? shift;
  final List<OvertimeRequest> overtimeRequests;

  // P5 — WFH / Break state
  final bool isWfh;
  final bool isOnBreak;
  final DateTime? breakStartTime;

  // P1 — Overtime form state
  final bool isSubmittingOvertime;

  const AttendanceLoaded({
    required this.todayStatus,
    required this.history,
    this.shift,
    this.overtimeRequests = const [],
    this.isWfh = false,
    this.isOnBreak = false,
    this.breakStartTime,
    this.isSubmittingOvertime = false,
  });

  AttendanceLoaded copyWith({
    AttendanceRecord? todayStatus,
    List<AttendanceRecord>? history,
    ShiftInfo? shift,
    List<OvertimeRequest>? overtimeRequests,
    bool? isWfh,
    bool? isOnBreak,
    DateTime? breakStartTime,
    bool clearBreakTime = false,
    bool? isSubmittingOvertime,
  }) {
    return AttendanceLoaded(
      todayStatus: todayStatus ?? this.todayStatus,
      history: history ?? this.history,
      shift: shift ?? this.shift,
      overtimeRequests: overtimeRequests ?? this.overtimeRequests,
      isWfh: isWfh ?? this.isWfh,
      isOnBreak: isOnBreak ?? this.isOnBreak,
      breakStartTime: clearBreakTime ? null : (breakStartTime ?? this.breakStartTime),
      isSubmittingOvertime: isSubmittingOvertime ?? this.isSubmittingOvertime,
    );
  }

  @override
  List<Object?> get props => [
        todayStatus,
        history,
        shift,
        overtimeRequests,
        isWfh,
        isOnBreak,
        breakStartTime,
        isSubmittingOvertime,
      ];
}

class AttendanceError extends AttendanceState {
  final String message;

  const AttendanceError(this.message);

  @override
  List<Object?> get props => [message];
}
