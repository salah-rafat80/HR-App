import 'package:hr_core/features/admin/domain/entities/payroll_run.dart';
import 'package:hr_core/features/admin/domain/repositories/admin_payroll_repository.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../../../core/bloc/web_cubits.dart';

class PayrollCubit extends WebCubit<List<PayrollRun>> {
  final AdminPayrollRepository _repo;
  final io.Socket _socket;

  PayrollCubit(this._repo, this._socket) : super(() => _repo.getPayrollRuns()) {
    _socket.on('entity.updated', _onEntityUpdated);
  }

  void _onEntityUpdated(data) {
    if ((data['entity'] == 'PayrollRun' || data['entity'] == 'Payslip') && !isClosed) {
      _loadSilently();
    }
  }

  Future<void> _loadSilently() async {
    try {
      final data = await fetchData();
      if (!isClosed) emit(WebSuccess<List<PayrollRun>>(data));
    } catch (_) {}
  }

  @override
  Future<void> close() {
    _socket.off('entity.updated', _onEntityUpdated);
    return super.close();
  }

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
