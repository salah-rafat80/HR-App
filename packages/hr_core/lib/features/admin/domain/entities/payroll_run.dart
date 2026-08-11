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

  factory PayrollRun.fromJson(Map<String, dynamic> json) {
    return PayrollRun(
      id: json['id'] as String,
      periodLabel: json['periodLabel'] as String,
      status: PayrollStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PayrollStatus.draft,
      ),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      employeeCount: json['employeeCount'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'periodLabel': periodLabel,
      'status': status.name,
      'totalAmount': totalAmount,
      'employeeCount': employeeCount,
    };
  }

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
