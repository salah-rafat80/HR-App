import 'package:flutter_bloc/flutter_bloc.dart';
import 'payroll_state.dart';
import '../../domain/repositories/payroll_repository.dart';

class PayrollCubit extends Cubit<PayrollState> {
  final PayrollRepository _repository;

  PayrollCubit(this._repository) : super(PayrollInitial());

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
