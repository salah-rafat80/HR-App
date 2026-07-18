class PayslipLineItem {
  final String label;
  final double amount;

  const PayslipLineItem({
    required this.label,
    required this.amount,
  });
}

class Payslip {
  final String id;
  final String monthLabel;
  final double baseSalary;
  final List<PayslipLineItem> allowances;
  final List<PayslipLineItem> deductions;

  const Payslip({
    required this.id,
    required this.monthLabel,
    required this.baseSalary,
    required this.allowances,
    required this.deductions,
  });

  double get totalAllowances => allowances.fold(0.0, (sum, item) => sum + item.amount);
  double get totalDeductions => deductions.fold(0.0, (sum, item) => sum + item.amount);
  double get netPay => baseSalary + totalAllowances - totalDeductions;
}

class YtdSummary {
  final double totalEarnings;
  final double totalDeductions;

  const YtdSummary({
    required this.totalEarnings,
    required this.totalDeductions,
  });

  double get netYtd => totalEarnings - totalDeductions;
}

class BonusNotice {
  final String monthLabel;
  final double amount;
  final String message;

  const BonusNotice({
    required this.monthLabel,
    required this.amount,
    required this.message,
  });
}
