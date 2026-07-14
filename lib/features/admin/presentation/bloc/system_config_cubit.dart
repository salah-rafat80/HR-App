import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/system_config_entities.dart';
import '../../domain/repositories/system_config_repository.dart';
import '../../../leave/domain/entities/leave_enums.dart';

import '../../../appraisal/domain/repositories/appraisal_repository.dart';

abstract class SystemConfigState {}

class SystemConfigInitial extends SystemConfigState {}
class SystemConfigLoading extends SystemConfigState {}
class SystemConfigLoaded extends SystemConfigState {
  final List<LeaveTypeConfig> leaveTypes;
  final List<Holiday> holidays;
  final List<DepartmentConfig> departments;
  SystemConfigLoaded(this.leaveTypes, this.holidays, this.departments);
}
class SystemConfigError extends SystemConfigState {
  final String message;
  SystemConfigError(this.message);
}

class SystemConfigCubit extends Cubit<SystemConfigState> {
  final SystemConfigRepository _repository;
  final AppraisalRepository _appraisalRepository;

  SystemConfigCubit(this._repository, this._appraisalRepository) : super(SystemConfigInitial());

  Future<void> fetchData() async {
    emit(SystemConfigLoading());
    try {
      final leaveTypes = await _repository.getLeaveTypeConfigs();
      final holidays = await _repository.getHolidays();
      final depts = await _repository.getDepartments();
      emit(SystemConfigLoaded(leaveTypes, holidays, depts));
    } catch (e) {
      emit(SystemConfigError(e.toString()));
    }
  }

  Future<void> updateLeaveDays(LeaveType type, int days) async {
    try {
      await _repository.updateLeaveTypeConfig(type, days);
      fetchData();
    } catch (e) {
      emit(SystemConfigError(e.toString()));
    }
  }

  Future<void> addHoliday(String name, DateTime date) async {
    try {
      await _repository.addHoliday(name, date);
      fetchData();
    } catch (e) {
      emit(SystemConfigError(e.toString()));
    }
  }

  Future<void> addDepartment(String name) async {
    try {
      await _repository.addDepartment(name);
      fetchData();
    } catch (e) {
      emit(SystemConfigError(e.toString()));
    }
  }

  Future<void> startNewAppraisalCycle(String label, DateTime dueDate) async {
    try {
      await _appraisalRepository.startNewCycle(label, dueDate);
      // Success, just stay loaded
    } catch (e) {
      emit(SystemConfigError(e.toString()));
    }
  }
}
