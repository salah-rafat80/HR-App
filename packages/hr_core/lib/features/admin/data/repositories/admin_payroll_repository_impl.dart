import '../../domain/entities/payroll_run.dart';
import '../../domain/repositories/admin_payroll_repository.dart';
import '../datasources/fake_admin_payroll_datasource.dart';

class AdminPayrollRepositoryImpl implements AdminPayrollRepository {
  final FakeAdminPayrollDataSource _dataSource;

  AdminPayrollRepositoryImpl(this._dataSource);

  @override
  Future<void> approveRun(String id) => _dataSource.approveRun(id);

  @override
  Future<void> createRun(String periodLabel) => _dataSource.createRun(periodLabel);

  @override
  Future<List<PayrollRun>> getPayrollRuns() => _dataSource.getPayrollRuns();

  @override
  Future<void> processRun(String id) => _dataSource.processRun(id);
}
