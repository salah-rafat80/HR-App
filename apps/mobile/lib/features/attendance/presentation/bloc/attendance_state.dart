import 'package:equatable/equatable.dart';
import 'package:hr_core/features/attendance/domain/entities/attendance_record.dart';
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

  const AttendanceLoaded({
    required this.todayStatus,
    required this.history,
    this.shift,
  });

  AttendanceLoaded copyWith({
    AttendanceRecord? todayStatus,
    List<AttendanceRecord>? history,
    ShiftInfo? shift,
  }) {
    return AttendanceLoaded(
      todayStatus: todayStatus ?? this.todayStatus,
      history: history ?? this.history,
      shift: shift ?? this.shift,
    );
  }

  @override
  List<Object?> get props => [todayStatus, history, shift];
}

class AttendanceError extends AttendanceState {
  final String message;

  const AttendanceError(this.message);

  @override
  List<Object?> get props => [message];
}
