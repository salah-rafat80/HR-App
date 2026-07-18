import '../../domain/entities/executive_entities.dart';
import '../../domain/repositories/executive_repository.dart';
import '../datasources/fake_executive_datasource.dart';
import '../../../admin/domain/entities/recruitment_entities.dart';
import '../../../admin/domain/entities/payroll_run.dart';
import '../../../admin/domain/repositories/recruitment_repository.dart';
import '../../../admin/domain/repositories/admin_payroll_repository.dart';
import '../../../engagement/domain/repositories/engagement_repository.dart';

class ExecutiveRepositoryImpl implements ExecutiveRepository {
  final FakeExecutiveDataSource _dataSource;
  final RecruitmentRepository _recruitmentRepository;
  final AdminPayrollRepository _payrollRepository;
  final EngagementRepository _engagementRepository;

  ExecutiveRepositoryImpl(this._dataSource, this._recruitmentRepository, this._payrollRepository, this._engagementRepository);

  @override
  Future<List<TrendPoint>> getAttendanceTrend() => _dataSource.getAttendanceTrend();

  @override
  Future<List<DeptHeadcount>> getDeptHeadcount() => _dataSource.getDeptHeadcount();

  @override
  Future<Map<String, double>> getKpiHeatmap() => _dataSource.getKpiHeatmap();

  @override
  Future<ExecutiveSummary> getSummary() async {
    final summary = await _dataSource.getSummary();
    final engagementScore = await _engagementRepository.getEngagementScorePercent();
    return ExecutiveSummary(
      totalEmployees: summary.totalEmployees,
      presentPercent: summary.presentPercent,
      onLeavePercent: summary.onLeavePercent,
      turnoverPercent: summary.turnoverPercent,
      avgKpiScorePercent: summary.avgKpiScorePercent,
      engagementScorePercent: engagementScore,
    );
  }

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
