import 'package:hr_core/features/admin/domain/entities/payroll_run.dart';
import 'package:hr_core/features/admin/domain/repositories/admin_payroll_repository.dart';
import '../../../../core/bloc/web_cubits.dart';

class PayrollCubit extends WebCubit<List<PayrollRun>> {
  final AdminPayrollRepository _repo;

  PayrollCubit(this._repo) : super(() => _repo.getPayrollRuns());

  Future<void> startNewRun() async {
    await _repo.createRun('September 2026');
    load();
  }

  Future<void> processRun(String id) async {
    await _repo.processRun(id);
    load();
  }

  Future<void> approveRun(String id) async {
    await _repo.approveRun(id);
    load();
  }
}

