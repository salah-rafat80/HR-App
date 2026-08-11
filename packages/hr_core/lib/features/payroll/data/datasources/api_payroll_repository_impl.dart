import 'package:dio/dio.dart';
import '../../domain/entities/payroll_entities.dart';
import '../../domain/repositories/payroll_repository.dart';

class ApiPayrollRepositoryImpl implements PayrollRepository {
  final Dio dio;

  ApiPayrollRepositoryImpl({required this.dio});

  @override
  Future<List<Payslip>> getPayslips() async {
    final response = await dio.get('/payroll/payslips');
    return (response.data as List)
        .map((e) => Payslip.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Payslip> getPayslipDetail(String monthLabel) async {
    final response = await dio.get('/payroll/payslips/$monthLabel');
    return Payslip.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<YtdSummary> getYtdSummary() async {
    final response = await dio.get('/payroll/ytd');
    return YtdSummary.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<BonusNotice?> getCurrentBonusNotice() async {
    final response = await dio.get('/payroll/bonus-notice');
    if (response.data == null) return null;
    return BonusNotice.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> downloadTaxCertificate() async {
    await dio.post('/payroll/tax-certificate/download');
  }
}
