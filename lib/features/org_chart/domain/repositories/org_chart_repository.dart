import '../entities/org_chart_entities.dart';

abstract class OrgChartRepository {
  Future<List<OrgNode>> getOrgChart();
}
