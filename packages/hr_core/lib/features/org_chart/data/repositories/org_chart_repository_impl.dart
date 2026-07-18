import '../../domain/entities/org_chart_entities.dart';
import '../../domain/repositories/org_chart_repository.dart';
import '../datasources/fake_org_chart_datasource.dart';

class OrgChartRepositoryImpl implements OrgChartRepository {
  final FakeOrgChartDataSource _dataSource;

  OrgChartRepositoryImpl(this._dataSource);

  @override
  Future<List<OrgNode>> getOrgChart() => _dataSource.getOrgChart();
}
