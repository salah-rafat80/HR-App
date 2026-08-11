class PayslipLineItem {
  final String label;
  final double amount;

  const PayslipLineItem({
    required this.label,
    required this.amount,
  });

  factory PayslipLineItem.fromJson(Map<String, dynamic> json) {
    return PayslipLineItem(
      label: json['label'] as String,
      amount: (json['amount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'amount': amount,
    };
  }

  PayslipLineItem copyWith({
    String? label,
    double? amount,
  }) {
    return PayslipLineItem(
      label: label ?? this.label,
      amount: amount ?? this.amount,
    );
  }
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

  factory Payslip.fromJson(Map<String, dynamic> json) {
    final rawLineItems = json['lineItems'] as List? ?? [];
    final allItems = rawLineItems.map((e) => e as Map<String, dynamic>).toList();
    
    final allowances = allItems
        .where((item) => item['type'] == 'allowance')
        .map((item) => PayslipLineItem.fromJson(item))
        .toList();
        
    final deductions = allItems
        .where((item) => item['type'] == 'deduction')
        .map((item) => PayslipLineItem.fromJson(item))
        .toList();

    return Payslip(
      id: json['id'] as String,
      monthLabel: json['monthLabel'] as String,
      baseSalary: (json['baseSalary'] as num).toDouble(),
      allowances: allowances,
      deductions: deductions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'monthLabel': monthLabel,
      'baseSalary': baseSalary,
      'lineItems': [
        ...allowances.map((e) => {...e.toJson(), 'type': 'allowance'}),
        ...deductions.map((e) => {...e.toJson(), 'type': 'deduction'}),
      ],
    };
  }

  Payslip copyWith({
    String? id,
    String? monthLabel,
    double? baseSalary,
    List<PayslipLineItem>? allowances,
    List<PayslipLineItem>? deductions,
  }) {
    return Payslip(
      id: id ?? this.id,
      monthLabel: monthLabel ?? this.monthLabel,
      baseSalary: baseSalary ?? this.baseSalary,
      allowances: allowances ?? this.allowances,
      deductions: deductions ?? this.deductions,
    );
  }
}

class YtdSummary {
  final double totalEarnings;
  final double totalDeductions;

  const YtdSummary({
    required this.totalEarnings,
    required this.totalDeductions,
  });

  double get netYtd => totalEarnings - totalDeductions;

  factory YtdSummary.fromJson(Map<String, dynamic> json) {
    return YtdSummary(
      totalEarnings: (json['totalEarnings'] as num).toDouble(),
      totalDeductions: (json['totalDeductions'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalEarnings': totalEarnings,
      'totalDeductions': totalDeductions,
    };
  }

  YtdSummary copyWith({
    double? totalEarnings,
    double? totalDeductions,
  }) {
    return YtdSummary(
      totalEarnings: totalEarnings ?? this.totalEarnings,
      totalDeductions: totalDeductions ?? this.totalDeductions,
    );
  }
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

  factory BonusNotice.fromJson(Map<String, dynamic> json) {
    return BonusNotice(
      monthLabel: json['monthLabel'] as String,
      amount: (json['amount'] as num).toDouble(),
      message: json['message'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'monthLabel': monthLabel,
      'amount': amount,
      'message': message,
    };
  }

  BonusNotice copyWith({
    String? monthLabel,
    double? amount,
    String? message,
  }) {
    return BonusNotice(
      monthLabel: monthLabel ?? this.monthLabel,
      amount: amount ?? this.amount,
      message: message ?? this.message,
    );
  }
}
