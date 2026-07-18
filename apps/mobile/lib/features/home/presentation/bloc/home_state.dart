import 'package:equatable/equatable.dart';
import 'package:hr_core/features/home/domain/entities/home_entities.dart';
import 'package:hr_core/features/attendance/domain/entities/attendance_record.dart';

sealed class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final HomeDashboardData data;
  final AttendanceRecord todayAttendance;

  const HomeLoaded({
    required this.data,
    required this.todayAttendance,
  });

  @override
  List<Object?> get props => [data, todayAttendance];
}

class HomeError extends HomeState {
  final String message;

  const HomeError(this.message);

  @override
  List<Object?> get props => [message];
}
