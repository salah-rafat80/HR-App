import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:hr_core/features/attendance/domain/entities/overtime_request.dart';
import 'package:hr_core/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:hr_core/features/admin/domain/entities/hr_report.dart';
import 'package:hr_core/features/admin/domain/repositories/hr_report_repository.dart';
import 'package:hr_web/features/reports/presentation/bloc/hr_reports_cubit.dart';
import 'package:hr_web/features/approvals/presentation/bloc/overtime_approvals_cubit.dart';

class MockAttendanceRepository implements AttendanceRepository {
  List<OvertimeRequest> mockPending = [];
  bool approveCalled = false;
  bool rejectCalled = false;

  @override
  Future<List<OvertimeRequest>> getPendingOvertimeApprovals() async {
    return mockPending;
  }

  @override
  Future<OvertimeRequest> approveOvertimeAsTeamLead(String requestId, {String? comment}) async {
    approveCalled = true;
    return mockPending.first;
  }

  @override
  Future<OvertimeRequest> rejectOvertimeAsTeamLead(String requestId, {String? comment}) async {
    rejectCalled = true;
    return mockPending.first;
  }

  @override
  Future<OvertimeRequest> approveOvertimeAsHr(String requestId, {String? comment}) async {
    approveCalled = true;
    return mockPending.first;
  }

  @override
  Future<OvertimeRequest> rejectOvertimeAsHr(String requestId, {String? comment}) async {
    rejectCalled = true;
    return mockPending.first;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockHrReportRepository implements HrReportRepository {
  @override
  Future<HrMonthlyReportData> getMonthlyReport({
    required String month,
    String? department,
    String? employeeId,
  }) async {
    return const HrMonthlyReportData(
      summary: HrMonthlySummary(
        month: '2026-08',
        totalEmployees: 10,
        totalWorkDays: 22,
        totalPresent: 200,
        totalAbsent: 20,
        totalLate: 2,
        totalOvertimeHours: 15.5,
        totalOvertimeCost: 310.0,
      ),
      employees: [],
    );
  }

  @override
  Future<Uint8List> exportMonthlyReportBytes({
    required String month,
    String? department,
    String? employeeId,
  }) async {
    return Uint8List.fromList([1, 2, 3, 4]);
  }
}

void main() {
  group('Web HR Reports & Approvals Unit Tests', () {
    late MockHrReportRepository mockHrRepo;
    late MockAttendanceRepository mockAttendanceRepo;
    late HrReportsCubit hrReportsCubit;
    late OvertimeApprovalsCubit overtimeApprovalsCubit;

    setUp(() {
      mockHrRepo = MockHrReportRepository();
      mockAttendanceRepo = MockAttendanceRepository();
      hrReportsCubit = HrReportsCubit(mockHrRepo);
      overtimeApprovalsCubit = OvertimeApprovalsCubit(mockAttendanceRepo);
    });

    tearDown(() {
      hrReportsCubit.close();
      overtimeApprovalsCubit.close();
    });

    test('HrReportsCubit validates YYYY-MM month format correctly', () {
      expect(hrReportsCubit.isValidMonthFormat('2026-08'), isTrue);
      expect(hrReportsCubit.isValidMonthFormat('2026-12'), isTrue);
      expect(hrReportsCubit.isValidMonthFormat('2026-8'), isFalse);
      expect(hrReportsCubit.isValidMonthFormat('invalid'), isFalse);
      expect(hrReportsCubit.isValidMonthFormat('2026-13'), isFalse);
    });

    test('HrReportsCubit emits error state on invalid month string', () async {
      await hrReportsCubit.fetchReport(month: 'invalid-month');
      expect(hrReportsCubit.state, isA<HrReportsError>());
      final errState = hrReportsCubit.state as HrReportsError;
      expect(errState.message, contains('Invalid month format'));
    });

    test('HrReportsCubit fetches report successfully for valid month', () async {
      await hrReportsCubit.fetchReport(month: '2026-08', department: 'IT');
      expect(hrReportsCubit.state, isA<HrReportsLoaded>());
      final loaded = hrReportsCubit.state as HrReportsLoaded;
      expect(loaded.reportData.summary.month, '2026-08');
      expect(loaded.reportData.summary.totalEmployees, 10);
    });

    test('OvertimeApprovalsCubit loads pending items and triggers decision without optimistic state', () async {
      mockAttendanceRepo.mockPending = [
        OvertimeRequest(
          id: 'req_100',
          userId: 'EMP-001',
          date: DateTime.now(),
          submittedAt: DateTime.now(),
          status: OvertimeStatus.pendingTeamLead,
          reason: 'Emergency audit',
        ),
      ];

      await overtimeApprovalsCubit.loadPendingRequests();
      expect(overtimeApprovalsCubit.state, isA<OvertimeApprovalsLoaded>());
      final loaded = overtimeApprovalsCubit.state as OvertimeApprovalsLoaded;
      expect(loaded.requests.length, 1);

      await overtimeApprovalsCubit.approveRequest(requestId: 'req_100', isHr: false, comment: 'Approved');
      expect(mockAttendanceRepo.approveCalled, isTrue);
    });
  });
}
