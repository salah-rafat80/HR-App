import '../../domain/entities/kpi_entities.dart';
import '../../../../core/enums/role_enums.dart';
import '../../../../core/constants/shared_team_members.dart';
import '../../../team/domain/entities/team_member.dart';

class FakeKpiDataSource {
  final List<Kpi> _kpis = [
    const Kpi(
      id: 'kpi_1',
      title: 'Customer Satisfaction Score',
      description: 'Maintain an average customer satisfaction score across all channels.',
      departmentObjective: 'Improve customer response time',
      targetValue: 4.8,
      currentValue: 4.6,
    ),
    const Kpi(
      id: 'kpi_2',
      title: 'Bug Resolution Time',
      description: 'Average time taken to resolve critical and high priority bugs.',
      departmentObjective: 'Reduce deployment defects',
      targetValue: 24,
      currentValue: 20, // Lower is better? No, progress is current/target, let's make it traditional
    ),
    const Kpi(
      id: 'kpi_3',
      title: 'Feature Delivery',
      description: 'Number of epics completed per quarter.',
      departmentObjective: 'Accelerate product roadmap',
      targetValue: 5,
      currentValue: 1,
    ),
    const Kpi(
      id: 'kpi_4',
      title: 'Code Coverage',
      description: 'Maintain unit test code coverage.',
      departmentObjective: 'Improve software quality',
      targetValue: 90,
      currentValue: 88,
    ),
  ];

  final List<KpiQuarterScore> _history = [
    const KpiQuarterScore(quarterLabel: 'Q2 2025', averageScorePercent: 0.72),
    const KpiQuarterScore(quarterLabel: 'Q3 2025', averageScorePercent: 0.78),
    const KpiQuarterScore(quarterLabel: 'Q4 2025', averageScorePercent: 0.81),
    const KpiQuarterScore(quarterLabel: 'Q1 2026', averageScorePercent: 0.85),
  ];

  Future<List<Kpi>> getCurrentKpis() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _kpis;
  }

  Future<List<KpiQuarterScore>> getHistoricalScores() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _history;
  }

  Future<void> submitSelfAssessment(String kpiId, String text) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final index = _kpis.indexWhere((k) => k.id == kpiId);
    if (index != -1) {
      final k = _kpis[index];
      // Slightly bump current value as a demo touch
      double newCurrent = k.currentValue + (k.targetValue * 0.05);
      if (newCurrent > k.targetValue) newCurrent = k.targetValue;
      
      _kpis[index] = k.copyWith(selfAssessmentText: text, currentValue: newCurrent);
    }
  }

  Future<void> attachEvidence(String kpiId) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final index = _kpis.indexWhere((k) => k.id == kpiId);
    if (index != -1) {
      _kpis[index] = _kpis[index].copyWith(hasEvidence: true);
    }
  }

  Future<double> getOverallQuarterScore() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (_kpis.isEmpty) return 0.0;
    final totalProgress = _kpis.fold<double>(0.0, (sum, kpi) {
      double p = kpi.targetValue > 0 ? (kpi.currentValue / kpi.targetValue) : 0;
      return sum + (p > 1.0 ? 1.0 : p);
    });
    return totalProgress / _kpis.length;
  }

  late List<TeamMember> _teamKpis = List.from(SharedTeamMembers.members);

  Future<List<TeamMember>> getTeamKpis(ApprovalScope scope) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _teamKpis;
  }

  Future<void> assignKpi(String memberId, Kpi draft) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final index = _teamKpis.indexWhere((m) => m.id == memberId);
    if (index != -1) {
      final old = _teamKpis[index];
      // Simulate that assigning a new KPI resets or adjusts their score
      // For demo visibility, we bump their score by 2% just to see the change
      final newScore = (old.kpiScorePercent + 0.02).clamp(0.0, 1.0);
      _teamKpis[index] = TeamMember(
        id: old.id,
        name: old.name,
        title: old.title,
        department: old.department,
        kpiScorePercent: newScore,
        leaveStatus: old.leaveStatus,
      );
    }
  }
}
