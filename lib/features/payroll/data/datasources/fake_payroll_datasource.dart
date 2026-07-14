import '../../domain/entities/payroll_entities.dart';

class FakePayrollDataSource {
  final List<Payslip> _payslips = [
    const Payslip(
      id: 'p1',
      monthLabel: 'June 2026',
      baseSalary: 12000,
      allowances: [
        PayslipLineItem(label: 'housing_allowance', amount: 3000),
        PayslipLineItem(label: 'transport_allowance', amount: 1000),
      ],
      deductions: [
        PayslipLineItem(label: 'tax_deduction', amount: 500),
        PayslipLineItem(label: 'social_insurance', amount: 1200),
      ],
    ),
    const Payslip(
      id: 'p2',
      monthLabel: 'May 2026',
      baseSalary: 12000,
      allowances: [
        PayslipLineItem(label: 'housing_allowance', amount: 3000),
        PayslipLineItem(label: 'transport_allowance', amount: 1000),
      ],
      deductions: [
        PayslipLineItem(label: 'tax_deduction', amount: 500),
        PayslipLineItem(label: 'social_insurance', amount: 1200),
      ],
    ),
    const Payslip(
      id: 'p3',
      monthLabel: 'April 2026',
      baseSalary: 12000,
      allowances: [
        PayslipLineItem(label: 'housing_allowance', amount: 3000),
        PayslipLineItem(label: 'transport_allowance', amount: 1000),
      ],
      deductions: [
        PayslipLineItem(label: 'tax_deduction', amount: 500),
        PayslipLineItem(label: 'social_insurance', amount: 1200),
        PayslipLineItem(label: 'loan_deduction', amount: 1000),
      ],
    ),
    const Payslip(
      id: 'p4',
      monthLabel: 'March 2026',
      baseSalary: 12000,
      allowances: [
        PayslipLineItem(label: 'housing_allowance', amount: 3000),
        PayslipLineItem(label: 'transport_allowance', amount: 1000),
      ],
      deductions: [
        PayslipLineItem(label: 'tax_deduction', amount: 500),
        PayslipLineItem(label: 'social_insurance', amount: 1200),
      ],
    ),
    const Payslip(
      id: 'p5',
      monthLabel: 'February 2026',
      baseSalary: 12000,
      allowances: [
        PayslipLineItem(label: 'housing_allowance', amount: 3000),
        PayslipLineItem(label: 'transport_allowance', amount: 1000),
        PayslipLineItem(label: 'meal_allowance', amount: 500),
      ],
      deductions: [
        PayslipLineItem(label: 'tax_deduction', amount: 525),
        PayslipLineItem(label: 'social_insurance', amount: 1200),
      ],
    ),
    const Payslip(
      id: 'p6',
      monthLabel: 'January 2026',
      baseSalary: 12000,
      allowances: [
        PayslipLineItem(label: 'housing_allowance', amount: 3000),
        PayslipLineItem(label: 'transport_allowance', amount: 1000),
      ],
      deductions: [
        PayslipLineItem(label: 'tax_deduction', amount: 500),
        PayslipLineItem(label: 'social_insurance', amount: 1200),
      ],
    ),
  ];

  final YtdSummary _ytdSummary = const YtdSummary(
    totalEarnings: 96500, // Roughly 6 months of base + allowances
    totalDeductions: 11225, // Roughly 6 months of deductions
  );

  final BonusNotice _currentBonus = const BonusNotice(
    monthLabel: 'June 2026',
    amount: 5000,
    message: 'Performance Bonus Q2',
  );

  Future<List<Payslip>> getPayslips() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _payslips;
  }

  Future<Payslip> getPayslipDetail(String monthLabel) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _payslips.firstWhere((p) => p.monthLabel == monthLabel);
  }

  Future<YtdSummary> getYtdSummary() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _ytdSummary;
  }

  Future<BonusNotice?> getCurrentBonusNotice() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _currentBonus;
  }

  Future<void> downloadTaxCertificate() async {
    await Future.delayed(const Duration(seconds: 2));
    // Simulate successful download
  }
}
