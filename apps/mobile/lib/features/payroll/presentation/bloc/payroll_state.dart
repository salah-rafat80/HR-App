import 'package:equatable/equatable.dart';
import 'package:hr_core/features/payroll/domain/entities/payroll_entities.dart';

sealed class PayrollState extends Equatable {
  const PayrollState();
  @override
  List<Object?> get props => [];
}

class PayrollInitial extends PayrollState {}

class PayrollLoading extends PayrollState {}

class PayrollLoaded extends PayrollState {
  final List<Payslip> payslips;
  final YtdSummary ytdSummary;
  final BonusNotice? bonusNotice;
  final bool isDownloadingTax;
  final bool downloadTaxSuccess;

  const PayrollLoaded({
    required this.payslips,
    required this.ytdSummary,
    this.bonusNotice,
    this.isDownloadingTax = false,
    this.downloadTaxSuccess = false,
  });

  PayrollLoaded copyWith({
    List<Payslip>? payslips,
    YtdSummary? ytdSummary,
    BonusNotice? bonusNotice,
    bool? isDownloadingTax,
    bool? downloadTaxSuccess,
  }) {
    return PayrollLoaded(
      payslips: payslips ?? this.payslips,
      ytdSummary: ytdSummary ?? this.ytdSummary,
      bonusNotice: bonusNotice ?? this.bonusNotice,
      isDownloadingTax: isDownloadingTax ?? this.isDownloadingTax,
      downloadTaxSuccess: downloadTaxSuccess ?? this.downloadTaxSuccess,
    );
  }

  @override
  List<Object?> get props => [payslips, ytdSummary, bonusNotice, isDownloadingTax, downloadTaxSuccess];
}

class PayrollError extends PayrollState {
  final String message;
  const PayrollError(this.message);
  @override
  List<Object?> get props => [message];
}
