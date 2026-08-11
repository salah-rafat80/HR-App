import 'package:hr_app_demo/core/utils/safe_cubit.dart';
import 'payroll_state.dart';
import 'package:hr_core/features/payroll/domain/repositories/payroll_repository.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class PayrollCubit extends SafeCubit<PayrollState> {
  final PayrollRepository _repository;
  final io.Socket _socket;

  PayrollCubit(this._repository, this._socket) : super(PayrollInitial()) {
    _socket.on('entity.updated', _onEntityUpdated);
  }

  void _onEntityUpdated(data) {
    if ((data['entity'] == 'Payslip' || data['entity'] == 'BonusNotice') && !isClosed) {
      loadData();
    }
  }

  @override
  Future<void> close() {
    _socket.off('entity.updated', _onEntityUpdated);
    return super.close();
  }

  Future<void> loadData() async {
    if (!isClosed) { emit(PayrollLoading()); }
    try {
      final payslips = await _repository.getPayslips();
      final ytd = await _repository.getYtdSummary();
      final bonus = await _repository.getCurrentBonusNotice();
      if (!isClosed) { emit(PayrollLoaded(payslips: payslips, ytdSummary: ytd, bonusNotice: bonus)); }
    } catch (e) {
      if (!isClosed) { emit(PayrollError(e.toString())); }
    }
  }

  Future<void> downloadTaxCertificate() async {
    if (state is! PayrollLoaded) return;
    final currentState = state as PayrollLoaded;
    if (!isClosed) { emit(currentState.copyWith(isDownloadingTax: true, downloadTaxSuccess: false)); }
    try {
      await _repository.downloadTaxCertificate();
      if (!isClosed) { emit(currentState.copyWith(isDownloadingTax: false, downloadTaxSuccess: true)); }
    } catch (e) {
      if (!isClosed) { emit(currentState.copyWith(isDownloadingTax: false, downloadTaxSuccess: false)); }
    }
  }
}
