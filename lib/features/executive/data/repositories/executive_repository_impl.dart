import '../../domain/entities/executive_entities.dart';
import '../../domain/repositories/executive_repository.dart';
import '../datasources/fake_executive_datasource.dart';
import '../../../admin/domain/entities/recruitment_entities.dart';
import '../../../admin/domain/entities/payroll_run.dart';
import '../../../admin/domain/repositories/recruitment_repository.dart';
import '../../../admin/domain/repositories/admin_payroll_repository.dart';

class ExecutiveRepositoryImpl implements ExecutiveRepository {
  final FakeExecutiveDataSource _dataSource;
  final RecruitmentRepository _recruitmentRepository;
  final AdminPayrollRepository _payrollRepository;

  ExecutiveRepositoryImpl(this._dataSource, this._recruitmentRepository, this._payrollRepository);

  @override
  Future<List<TrendPoint>> getAttendanceTrend() => _dataSource.getAttendanceTrend();

  @override
  Future<List<DeptHeadcount>> getDeptHeadcount() => _dataSource.getDeptHeadcount();

  @override
  Future<Map<String, double>> getKpiHeatmap() => _dataSource.getKpiHeatmap();

  @override
  Future<ExecutiveSummary> getSummary() => _dataSource.getSummary();

  @override
  Future<List<TrendPoint>> getTurnoverForecast() => _dataSource.getTurnoverForecast();

  @override
  Future<Map<CandidateStage, int>> getRecruitmentPipelineSummary() async {
    final jobs = await _recruitmentRepository.getJobRequisitions();
    final Map<CandidateStage, int> counts = {
      for (var stage in CandidateStage.values) stage: 0
    };
    for (final job in jobs) {
      final candidates = await _recruitmentRepository.getCandidates(job.id);
      for (final c in candidates) {
        counts[c.stage] = (counts[c.stage] ?? 0) + 1;
      }
    }
    return counts;
  }

  @override
  Future<Map<PayrollStatus, double>> getPayrollSummary() async {
    final runs = await _payrollRepository.getPayrollRuns();
    final Map<PayrollStatus, double> summary = {
      for (var status in PayrollStatus.values) status: 0.0
    };
    for (final run in runs) {
      summary[run.status] = (summary[run.status] ?? 0.0) + run.totalAmount;
    }
    return summary;
  }
}
