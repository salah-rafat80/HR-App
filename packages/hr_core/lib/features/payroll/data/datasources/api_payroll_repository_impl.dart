import 'package:dio/dio.dart';
import '../../domain/entities/payroll_entities.dart';
import '../../domain/repositories/payroll_repository.dart';

class ApiPayrollRepositoryImpl implements PayrollRepository {
  final Dio dio;

  ApiPayrollRepositoryImpl({required this.dio});

  @override
  Future<List<Payslip>> getPayslips() async {
    final response = await dio.get('/payroll/payslips');
    if (response.data == null || response.data is! List) return [];
    return (response.data as List)
        .map((e) => Payslip.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Payslip> getPayslipDetail(String monthLabel) async {
    final response = await dio.get('/payroll/payslips/$monthLabel');
    if (response.data is! Map) {
      return Payslip(id: '', monthLabel: monthLabel, baseSalary: 0, allowances: [], deductions: []);
    }
    return Payslip.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<YtdSummary> getYtdSummary() async {
    final response = await dio.get('/payroll/ytd');
    if (response.data is! Map) {
      return const YtdSummary(totalEarnings: 0, totalDeductions: 0);
    }
    return YtdSummary.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<BonusNotice?> getCurrentBonusNotice() async {
    final response = await dio.get('/payroll/bonus-notice');
    if (response.data == null || response.data is! Map) return null;
    return BonusNotice.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> downloadTaxCertificate() async {
    await dio.post('/payroll/tax-certificate/download');
  }
}
