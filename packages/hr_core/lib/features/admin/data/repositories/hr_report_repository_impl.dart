import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../domain/entities/hr_report.dart';
import '../../domain/repositories/hr_report_repository.dart';

class ApiHrReportRepositoryImpl implements HrReportRepository {
  final Dio dio;

  ApiHrReportRepositoryImpl(this.dio);

  @override
  Future<HrMonthlyReportData> getMonthlyReport({
    required String month,
    String? department,
    String? employeeId,
  }) async {
    final queryParams = <String, dynamic>{
      'month': month,
    };
    if (department != null && department.isNotEmpty) {
      queryParams['department'] = department;
    }
    if (employeeId != null && employeeId.isNotEmpty) {
      queryParams['employeeId'] = employeeId;
    }

    final response = await dio.get(
      '/hr-reports/monthly',
      queryParameters: queryParams,
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return HrMonthlyReportData.fromJson(data);
    }
    throw Exception('Invalid report response shape');
  }

  @override
  Future<Uint8List> exportMonthlyReportBytes({
    required String month,
    String? department,
    String? employeeId,
  }) async {
    final queryParams = <String, dynamic>{
      'month': month,
    };
    if (department != null && department.isNotEmpty) {
      queryParams['department'] = department;
    }
    if (employeeId != null && employeeId.isNotEmpty) {
      queryParams['employeeId'] = employeeId;
    }

    final response = await dio.get<List<int>>(
      '/hr-reports/monthly/export',
      queryParameters: queryParams,
      options: Options(responseType: ResponseType.bytes),
    );

    if (response.data != null) {
      return Uint8List.fromList(response.data!);
    }
    throw Exception('Failed to download Excel report byte stream');
  }
}
