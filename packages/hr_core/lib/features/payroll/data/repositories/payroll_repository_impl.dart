import '../../domain/entities/payroll_entities.dart';
import '../../domain/repositories/payroll_repository.dart';
import '../datasources/fake_payroll_datasource.dart';

class PayrollRepositoryImpl implements PayrollRepository {
  final FakePayrollDataSource _dataSource;

  PayrollRepositoryImpl(this._dataSource);

  @override
  Future<void> downloadTaxCertificate() => _dataSource.downloadTaxCertificate();

  @override
  Future<BonusNotice?> getCurrentBonusNotice() => _dataSource.getCurrentBonusNotice();

  @override
  Future<Payslip> getPayslipDetail(String monthLabel) => _dataSource.getPayslipDetail(monthLabel);

  @override
  Future<List<Payslip>> getPayslips() => _dataSource.getPayslips();

  @override
  Future<YtdSummary> getYtdSummary() => _dataSource.getYtdSummary();
}
