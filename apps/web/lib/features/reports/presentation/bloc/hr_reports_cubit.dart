import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hr_core/features/admin/domain/entities/hr_report.dart';
import 'package:hr_core/features/admin/domain/repositories/hr_report_repository.dart';
import '../../../../core/utils/file_download_helper.dart';

abstract class HrReportsState extends Equatable {
  const HrReportsState();
  @override
  List<Object?> get props => [];
}

class HrReportsInitial extends HrReportsState {}

class HrReportsLoading extends HrReportsState {}

class HrReportsLoaded extends HrReportsState {
  final HrMonthlyReportData reportData;
  final String selectedMonth;
  final String? selectedDepartment;
  final String? selectedEmployeeId;

  const HrReportsLoaded({
    required this.reportData,
    required this.selectedMonth,
    this.selectedDepartment,
    this.selectedEmployeeId,
  });

  @override
  List<Object?> get props => [reportData, selectedMonth, selectedDepartment, selectedEmployeeId];
}

class HrReportsExporting extends HrReportsState {}

class HrReportsExportSuccess extends HrReportsState {
  final String filename;

  const HrReportsExportSuccess(this.filename);

  @override
  List<Object?> get props => [filename];
}

class HrReportsError extends HrReportsState {
  final String message;

  const HrReportsError(this.message);

  @override
  List<Object?> get props => [message];
}

class HrReportsCubit extends Cubit<HrReportsState> {
  final HrReportRepository repository;

  HrReportsCubit(this.repository) : super(HrReportsInitial());

  bool isValidMonthFormat(String month) {
    final regex = RegExp(r'^\d{4}-(0[1-9]|1[0-2])$');
    return regex.hasMatch(month);
  }

  Future<void> fetchReport({
    required String month,
    String? department,
    String? employeeId,
  }) async {
    if (!isValidMonthFormat(month)) {
      emit(const HrReportsError('Invalid month format. Please use YYYY-MM (e.g. 2026-08)'));
      return;
    }

    emit(HrReportsLoading());
    try {
      final data = await repository.getMonthlyReport(
        month: month,
        department: (department != null && department.isNotEmpty && department != 'All') ? department : null,
        employeeId: (employeeId != null && employeeId.isNotEmpty) ? employeeId : null,
      );
      emit(HrReportsLoaded(
        reportData: data,
        selectedMonth: month,
        selectedDepartment: department,
        selectedEmployeeId: employeeId,
      ));
    } catch (e) {
      emit(HrReportsError('Failed to fetch HR report: ${e.toString()}'));
    }
  }

  Future<void> exportExcel({
    required String month,
    String? department,
    String? employeeId,
  }) async {
    if (!isValidMonthFormat(month)) {
      emit(const HrReportsError('Invalid month format. Please use YYYY-MM'));
      return;
    }

    emit(HrReportsExporting());
    try {
      final bytes = await repository.exportMonthlyReportBytes(
        month: month,
        department: (department != null && department.isNotEmpty && department != 'All') ? department : null,
        employeeId: (employeeId != null && employeeId.isNotEmpty) ? employeeId : null,
      );

      final filename = 'hr_monthly_report_$month.xlsx';
      FileDownloadHelper.downloadBytes(bytes, filename);

      emit(HrReportsExportSuccess(filename));

      // Reload report state
      await fetchReport(month: month, department: department, employeeId: employeeId);
    } catch (e) {
      emit(HrReportsError('Excel Export failed: ${e.toString()}'));
      await fetchReport(month: month, department: department, employeeId: employeeId);
    }
  }
}
