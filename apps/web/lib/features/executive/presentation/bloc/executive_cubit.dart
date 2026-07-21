import 'package:hr_core/features/admin/domain/entities/recruitment_entities.dart';
import 'package:hr_core/features/admin/domain/entities/payroll_run.dart';
import 'package:hr_core/features/executive/domain/entities/executive_entities.dart';
import 'package:hr_core/features/executive/domain/repositories/executive_repository.dart';
import '../../../../core/bloc/web_cubits.dart';

class ExecutiveDashboardData {
  final ExecutiveSummary summary;
  final List<TrendPoint> attendanceTrend;
  final Map<String, double> kpiHeatmap;
  final List<DeptHeadcount> deptHeadcount;
  final Map<CandidateStage, int> recruitmentPipeline;
  final Map<PayrollStatus, double> payrollSummary;
  final List<TrendPoint> turnoverForecast;

  const ExecutiveDashboardData({
    required this.summary,
    required this.attendanceTrend,
    required this.kpiHeatmap,
    required this.deptHeadcount,
    required this.recruitmentPipeline,
    required this.payrollSummary,
    required this.turnoverForecast,
  });
}

class ExecutiveCubit extends WebCubit<ExecutiveDashboardData> {
  ExecutiveCubit(ExecutiveRepository repo) : super(() => _fetch(repo));

  static Future<ExecutiveDashboardData> _fetch(ExecutiveRepository repo) async {
    final summary = await repo.getSummary();
    final attendanceTrend = await repo.getAttendanceTrend();
    final kpiHeatmap = await repo.getKpiHeatmap();
    final deptHeadcount = await repo.getDeptHeadcount();
    final recruitmentPipeline = await repo.getRecruitmentPipelineSummary();
    final payrollSummary = await repo.getPayrollSummary();
    final turnoverForecast = await repo.getTurnoverForecast();

    return ExecutiveDashboardData(
      summary: summary,
      attendanceTrend: attendanceTrend,
      kpiHeatmap: kpiHeatmap,
      deptHeadcount: deptHeadcount,
      recruitmentPipeline: recruitmentPipeline,
      payrollSummary: payrollSummary,
      turnoverForecast: turnoverForecast,
    );
  }

  Future<void> refresh() => load();
}
