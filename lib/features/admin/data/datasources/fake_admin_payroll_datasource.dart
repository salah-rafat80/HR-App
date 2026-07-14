import '../../domain/entities/payroll_run.dart';

class FakeAdminPayrollDataSource {
  final List<PayrollRun> _runs = [
    const PayrollRun(id: 'pr_1', periodLabel: 'April 2026', status: PayrollStatus.paid, totalAmount: 1250000, employeeCount: 150),
    const PayrollRun(id: 'pr_2', periodLabel: 'May 2026', status: PayrollStatus.pendingApproval, totalAmount: 1300000, employeeCount: 152),
    const PayrollRun(id: 'pr_3', periodLabel: 'June 2026', status: PayrollStatus.draft, totalAmount: 1280000, employeeCount: 155),
  ];

  Future<List<PayrollRun>> getPayrollRuns() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _runs;
  }

  Future<void> createRun(String periodLabel) async {
    await Future.delayed(const Duration(milliseconds: 600));
    _runs.insert(0, PayrollRun(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      periodLabel: periodLabel,
      status: PayrollStatus.draft,
      totalAmount: 0,
      employeeCount: 0,
    ));
  }

  Future<void> processRun(String id) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final index = _runs.indexWhere((r) => r.id == id);
    if (index != -1 && _runs[index].status == PayrollStatus.draft) {
      _runs[index] = _runs[index].copyWith(status: PayrollStatus.pendingApproval);
    }
  }

  Future<void> approveRun(String id) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final index = _runs.indexWhere((r) => r.id == id);
    if (index != -1 && _runs[index].status == PayrollStatus.pendingApproval) {
      _runs[index] = _runs[index].copyWith(status: PayrollStatus.approved);
    }
  }
}
