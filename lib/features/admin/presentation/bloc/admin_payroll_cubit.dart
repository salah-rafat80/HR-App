import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/payroll_run.dart';
import '../../domain/repositories/admin_payroll_repository.dart';

abstract class AdminPayrollState {}

class AdminPayrollInitial extends AdminPayrollState {}
class AdminPayrollLoading extends AdminPayrollState {}
class AdminPayrollLoaded extends AdminPayrollState {
  final List<PayrollRun> runs;
  AdminPayrollLoaded(this.runs);
}
class AdminPayrollError extends AdminPayrollState {
  final String message;
  AdminPayrollError(this.message);
}

class AdminPayrollCubit extends Cubit<AdminPayrollState> {
  final AdminPayrollRepository _repository;

  AdminPayrollCubit(this._repository) : super(AdminPayrollInitial());

  Future<void> fetchRuns() async {
    emit(AdminPayrollLoading());
    try {
      final runs = await _repository.getPayrollRuns();
      emit(AdminPayrollLoaded(runs));
    } catch (e) {
      emit(AdminPayrollError(e.toString()));
    }
  }

  Future<void> createRun(String periodLabel) async {
    try {
      await _repository.createRun(periodLabel);
      fetchRuns();
    } catch (e) {
      emit(AdminPayrollError(e.toString()));
    }
  }

  Future<void> processRun(String id) async {
    try {
      await _repository.processRun(id);
      fetchRuns();
    } catch (e) {
      emit(AdminPayrollError(e.toString()));
    }
  }

  Future<void> approveRun(String id) async {
    try {
      await _repository.approveRun(id);
      fetchRuns();
    } catch (e) {
      emit(AdminPayrollError(e.toString()));
    }
  }
}
