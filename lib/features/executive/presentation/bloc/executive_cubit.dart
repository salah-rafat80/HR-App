import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/executive_entities.dart';
import '../../domain/repositories/executive_repository.dart';
import '../../../admin/domain/entities/recruitment_entities.dart';
import '../../../admin/domain/entities/payroll_run.dart';

abstract class ExecutiveState {}

class ExecutiveInitial extends ExecutiveState {}
class ExecutiveLoading extends ExecutiveState {}
class ExecutiveLoaded extends ExecutiveState {
  final ExecutiveSummary summary;
  final List<TrendPoint> attendanceTrend;
  final Map<String, double> kpiHeatmap;
  final List<DeptHeadcount> deptHeadcount;
  final List<TrendPoint> turnoverForecast;
  final Map<CandidateStage, int> recruitmentSummary;
  final Map<PayrollStatus, double> payrollSummary;

  ExecutiveLoaded({
    required this.summary,
    required this.attendanceTrend,
    required this.kpiHeatmap,
    required this.deptHeadcount,
    required this.turnoverForecast,
    required this.recruitmentSummary,
    required this.payrollSummary,
  });
}
class ExecutiveError extends ExecutiveState {
  final String message;
  ExecutiveError(this.message);
}

class ExecutiveCubit extends Cubit<ExecutiveState> {
  final ExecutiveRepository _repository;

  ExecutiveCubit(this._repository) : super(ExecutiveInitial());

  Future<void> loadDashboard() async {
    emit(ExecutiveLoading());
    try {
      final summary = await _repository.getSummary();
      final attendance = await _repository.getAttendanceTrend();
      final kpi = await _repository.getKpiHeatmap();
      final depts = await _repository.getDeptHeadcount();
      final turnover = await _repository.getTurnoverForecast();
      final recruitment = await _repository.getRecruitmentPipelineSummary();
      final payroll = await _repository.getPayrollSummary();

      emit(ExecutiveLoaded(
        summary: summary,
        attendanceTrend: attendance,
        kpiHeatmap: kpi,
        deptHeadcount: depts,
        turnoverForecast: turnover,
        recruitmentSummary: recruitment,
        payrollSummary: payroll,
      ));
    } catch (e) {
      emit(ExecutiveError(e.toString()));
    }
  }
}
