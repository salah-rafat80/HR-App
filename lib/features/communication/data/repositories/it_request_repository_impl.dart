import '../../domain/entities/it_request_entities.dart';
import '../../domain/repositories/it_request_repository.dart';
import '../datasources/fake_it_request_datasource.dart';

class ItRequestRepositoryImpl implements ItRequestRepository {
  final FakeItRequestDataSource _dataSource;

  ItRequestRepositoryImpl(this._dataSource);

  @override
  Future<List<ItRequest>> getMyItRequests() => _dataSource.getMyItRequests();

  @override
  Future<void> submitItRequest(ItRequestCategory category, String description) => _dataSource.submitItRequest(category, description);
}
