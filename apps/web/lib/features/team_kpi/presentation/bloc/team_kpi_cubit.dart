import 'package:hr_core/features/kpi/domain/repositories/kpi_repository.dart';
import 'package:hr_core/features/kpi/domain/entities/kpi_entities.dart';
import 'package:hr_core/features/team/domain/entities/team_member.dart';
import 'package:hr_core/core/enums/role_enums.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../../../core/bloc/web_cubits.dart';

class TeamKpiCubit extends WebCubit<List<TeamMember>> {
  final KpiRepository _repo;
  final io.Socket _socket;

  TeamKpiCubit(this._repo, this._socket) : super(() => _repo.getTeamKpis(ApprovalScope.all)) {
    _socket.on('entity.updated', _onEntityUpdated);
  }

  void _onEntityUpdated(data) {
    if (data['entity'] == 'Kpi' && !isClosed) {
      _loadSilently();
    }
  }

  Future<void> _loadSilently() async {
    try {
      final data = await fetchData();
      if (!isClosed) emit(WebSuccess<List<TeamMember>>(data));
    } catch (_) {}
  }

  @override
  Future<void> close() {
    _socket.off('entity.updated', _onEntityUpdated);
    return super.close();
  }

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
