import 'package:hr_app_demo/core/utils/safe_cubit.dart';
import '../../domain/entities/org_chart_entities.dart';
import '../../domain/repositories/org_chart_repository.dart';

abstract class OrgChartState {}

class OrgChartInitial extends OrgChartState {}
class OrgChartLoading extends OrgChartState {}
class OrgChartLoaded extends OrgChartState {
  final List<OrgNode> nodes;
  final OrgNode? rootNode;
  final Map<String, List<OrgNode>> childrenMap;

  OrgChartLoaded({required this.nodes, this.rootNode, required this.childrenMap});
}
class OrgChartError extends OrgChartState {
  final String message;
  OrgChartError(this.message);
}

class OrgChartCubit extends SafeCubit<OrgChartState> {
  final OrgChartRepository _repository;

  OrgChartCubit(this._repository) : super(OrgChartInitial());

  Future<void> fetchData() async {
    emit(OrgChartLoading());
    try {
      final nodes = await _repository.getOrgChart();
      
      OrgNode? rootNode;
      final childrenMap = <String, List<OrgNode>>{};
      
      for (final node in nodes) {
        if (node.managerId == null) {
          rootNode = node;
        } else {
          childrenMap.putIfAbsent(node.managerId!, () => []).add(node);
        }
      }

      emit(OrgChartLoaded(nodes: nodes, rootNode: rootNode, childrenMap: childrenMap));
    } catch (e) {
      emit(OrgChartError(e.toString()));
    }
  }
}
