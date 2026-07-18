import '../../domain/entities/offboarding_entities.dart';
import '../../domain/repositories/offboarding_repository.dart';
import '../datasources/fake_offboarding_datasource.dart';

class OffboardingRepositoryImpl implements OffboardingRepository {
  final FakeOffboardingDataSource _dataSource;

  OffboardingRepositoryImpl(this._dataSource);

  @override
  Future<List<OffboardingCase>> getOffboardingCases() => _dataSource.getOffboardingCases();

  @override
  Future<void> initiateOffboarding(String employeeName, String lastWorkingDay) => _dataSource.initiateOffboarding(employeeName, lastWorkingDay);

  @override
  Future<void> toggleOffboardingTask(String caseId, String taskId) => _dataSource.toggleOffboardingTask(caseId, taskId);
}
