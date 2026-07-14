import '../entities/payroll_entities.dart';

abstract class PayrollRepository {
  Future<List<Payslip>> getPayslips();
  Future<Payslip> getPayslipDetail(String monthLabel);
  Future<YtdSummary> getYtdSummary();
  Future<BonusNotice?> getCurrentBonusNotice();
  Future<void> downloadTaxCertificate();
}
