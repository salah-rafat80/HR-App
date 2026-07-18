import '../entities/executive_entities.dart';
import '../../../admin/domain/entities/recruitment_entities.dart';
import '../../../admin/domain/entities/payroll_run.dart';

abstract class ExecutiveRepository {
  Future<ExecutiveSummary> getSummary();
  Future<List<TrendPoint>> getAttendanceTrend();
  Future<Map<String, double>> getKpiHeatmap(); // department -> average KPI
  Future<List<DeptHeadcount>> getDeptHeadcount();
  
  // Cross-module
  Future<Map<CandidateStage, int>> getRecruitmentPipelineSummary();
  Future<Map<PayrollStatus, double>> getPayrollSummary();
  
  Future<List<TrendPoint>> getTurnoverForecast();
}
