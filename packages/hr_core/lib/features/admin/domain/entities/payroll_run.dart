import 'package:equatable/equatable.dart';

enum PayrollStatus { draft, processing, pendingApproval, approved, paid }

class PayrollRun extends Equatable {
  final String id;
  final String periodLabel;
  final PayrollStatus status;
  final double totalAmount;
  final int employeeCount;

  const PayrollRun({
    required this.id,
    required this.periodLabel,
    required this.status,
    required this.totalAmount,
    required this.employeeCount,
  });

  PayrollRun copyWith({
    PayrollStatus? status,
  }) {
    return PayrollRun(
      id: id,
      periodLabel: periodLabel,
      status: status ?? this.status,
      totalAmount: totalAmount,
      employeeCount: employeeCount,
    );
  }

  @override
  List<Object?> get props => [id, periodLabel, status, totalAmount, employeeCount];
}
