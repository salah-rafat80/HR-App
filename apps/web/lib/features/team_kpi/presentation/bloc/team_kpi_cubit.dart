import 'package:hr_core/features/kpi/domain/repositories/kpi_repository.dart';
import 'package:hr_core/features/kpi/domain/entities/kpi_entities.dart';
import 'package:hr_core/features/team/domain/entities/team_member.dart';
import 'package:hr_core/core/enums/role_enums.dart';
import '../../../../core/bloc/web_cubits.dart';

class TeamKpiCubit extends WebCubit<List<TeamMember>> {
  final KpiRepository _repo;

  TeamKpiCubit(this._repo) : super(() => _repo.getTeamKpis(ApprovalScope.all));

  Future<void> assignKpi(String memberId, String title) async {
    final draft = Kpi(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: 'Newly assigned KPI',
      departmentObjective: 'Improve overall team output',
      targetValue: 100,
      currentValue: 0,
    );
    await _repo.assignKpi(memberId, draft);
    load();
  }
}
