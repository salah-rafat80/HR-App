import 'package:dio/dio.dart';
import '../../domain/entities/payroll_run.dart';
import '../../domain/repositories/admin_payroll_repository.dart';

class ApiAdminPayrollRepositoryImpl implements AdminPayrollRepository {
  final Dio dio;

  ApiAdminPayrollRepositoryImpl({required this.dio});

  @override
  Future<List<PayrollRun>> getPayrollRuns() async {
    final response = await dio.get('/payroll/runs');
    return (response.data as List)
        .map((e) => PayrollRun.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> createRun(String periodLabel) async {
    await dio.post(
      '/payroll/runs',
      data: {'periodLabel': periodLabel},
    );
  }

  @override
  Future<void> processRun(String id) async {
    await dio.post('/payroll/runs/$id/process');
  }

  @override
  Future<void> approveRun(String id) async {
    await dio.post('/payroll/runs/$id/approve');
  }
}
