import '../entities/kpi_entities.dart';

import '../../../team/domain/entities/team_member.dart';
import '../../../../core/enums/role_enums.dart';

abstract class KpiRepository {
  Future<List<Kpi>> getCurrentKpis();
  Future<List<KpiQuarterScore>> getHistoricalScores();
  Future<void> submitSelfAssessment(String kpiId, String text);
  Future<void> attachEvidence(String kpiId);
  Future<double> getOverallQuarterScore();
  Future<List<TeamMember>> getTeamKpis(ApprovalScope scope);
  Future<void> assignKpi(String memberId, Kpi draft);
}
