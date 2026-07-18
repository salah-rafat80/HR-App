import '../../domain/entities/kpi_entities.dart';
import '../../domain/repositories/kpi_repository.dart';
import '../datasources/fake_kpi_datasource.dart';
import '../../../team/domain/entities/team_member.dart';
import '../../../../core/enums/role_enums.dart';

class KpiRepositoryImpl implements KpiRepository {
  final FakeKpiDataSource _dataSource;

  KpiRepositoryImpl(this._dataSource);

  @override
  Future<void> attachEvidence(String kpiId) => _dataSource.attachEvidence(kpiId);

  @override
  Future<List<Kpi>> getCurrentKpis() => _dataSource.getCurrentKpis();

  @override
  Future<List<KpiQuarterScore>> getHistoricalScores() => _dataSource.getHistoricalScores();

  @override
  Future<double> getOverallQuarterScore() => _dataSource.getOverallQuarterScore();

  @override
  Future<void> submitSelfAssessment(String kpiId, String text) => _dataSource.submitSelfAssessment(kpiId, text);

  @override
  Future<List<TeamMember>> getTeamKpis(ApprovalScope scope) => _dataSource.getTeamKpis(scope);

  @override
  Future<void> assignKpi(String memberId, Kpi draft) => _dataSource.assignKpi(memberId, draft);
}
