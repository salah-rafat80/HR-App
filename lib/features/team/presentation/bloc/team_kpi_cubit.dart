import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/enums/role_enums.dart';
import '../../domain/entities/team_member.dart';
import '../../../kpi/domain/repositories/kpi_repository.dart';
import '../../../kpi/domain/entities/kpi_entities.dart';

abstract class TeamKpiState {}

class TeamKpiInitial extends TeamKpiState {}
class TeamKpiLoading extends TeamKpiState {}
class TeamKpiLoaded extends TeamKpiState {
  final List<TeamMember> members;
  TeamKpiLoaded(this.members);
}
class TeamKpiError extends TeamKpiState {
  final String message;
  TeamKpiError(this.message);
}

class TeamKpiCubit extends Cubit<TeamKpiState> {
  final KpiRepository _kpiRepository;

  TeamKpiCubit(this._kpiRepository) : super(TeamKpiInitial());

  Future<void> fetchTeamKpis(ApprovalScope scope) async {
    emit(TeamKpiLoading());
    try {
      final members = await _kpiRepository.getTeamKpis(scope);
      emit(TeamKpiLoaded(members));
    } catch (e) {
      emit(TeamKpiError(e.toString()));
    }
  }

  Future<void> assignKpi(String memberId, Kpi draft, ApprovalScope scope) async {
    try {
      await _kpiRepository.assignKpi(memberId, draft);
      // Refresh
      fetchTeamKpis(scope);
    } catch (e) {
      emit(TeamKpiError(e.toString()));
    }
  }
}
