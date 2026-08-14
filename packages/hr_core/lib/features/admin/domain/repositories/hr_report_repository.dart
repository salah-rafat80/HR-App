import 'dart:typed_data';
import '../entities/hr_report.dart';

abstract class HrReportRepository {
  Future<HrMonthlyReportData> getMonthlyReport({
    required String month,
    String? department,
    String? employeeId,
  });

  Future<Uint8List> exportMonthlyReportBytes({
    required String month,
    String? department,
    String? employeeId,
  });
}
