import '../../domain/entities/home_entities.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/fake_home_datasource.dart';

class HomeRepositoryImpl implements HomeRepository {
  final FakeHomeDataSource _dataSource;

  HomeRepositoryImpl(this._dataSource);

  @override
  Future<HomeDashboardData> getDashboardData() {
    return _dataSource.getDashboardData();
  }
}
