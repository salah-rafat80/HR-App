import 'package:dio/dio.dart';
import '../../domain/entities/kpi_entities.dart';
import '../../domain/repositories/kpi_repository.dart';
import '../../../team/domain/entities/team_member.dart';
import '../../../../core/enums/role_enums.dart';

class ApiKpiRepositoryImpl implements KpiRepository {
  final Dio dio;

  ApiKpiRepositoryImpl({required this.dio});

  @override
  Future<List<Kpi>> getCurrentKpis() async {
    final response = await dio.get('/kpi/current');
    return (response.data as List).map((e) => Kpi.fromJson(e)).toList();
  }

  @override
  Future<List<KpiQuarterScore>> getHistoricalScores() async {
    final response = await dio.get('/kpi/history');
    return (response.data as List).map((e) => KpiQuarterScore.fromJson(e)).toList();
  }

  @override
  Future<void> submitSelfAssessment(String kpiId, String text) async {
    await dio.post('/kpi/$kpiId/self-assessment', data: {'text': text});
  }

  @override
  Future<void> attachEvidence(String kpiId) async {
    await dio.post('/kpi/$kpiId/evidence');
  }

  @override
  Future<double> getOverallQuarterScore() async {
    final response = await dio.get('/kpi/overall-score');
    if (response.data is Map) {
      return (response.data['overallScore'] as num).toDouble();
    }
    return (response.data as num).toDouble();
  }

  @override
  Future<List<TeamMember>> getTeamKpis(ApprovalScope scope) async {
    final response = await dio.get('/kpi/team');
    return (response.data as List).map((e) => TeamMember.fromJson(e)).toList();
  }

  @override
  Future<void> assignKpi(String memberId, Kpi draft) async {
    await dio.post('/kpi/assign', data: {
      'memberId': memberId,
      'title': draft.title,
      'description': draft.description,
      'departmentObjective': draft.departmentObjective,
      'targetValue': draft.targetValue,
    });
  }
}
