import '../entities/payroll_run.dart';

abstract class AdminPayrollRepository {
  Future<List<PayrollRun>> getPayrollRuns();
  Future<void> createRun(String periodLabel);
  Future<void> processRun(String id);
  Future<void> approveRun(String id);
}
