import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hr_core/core/enums/role_enums.dart';
import 'package:hr_core/features/leave/domain/entities/leave_enums.dart';
import 'package:hr_core/features/leave/domain/entities/leave_policy.dart';
import 'package:hr_core/features/leave/domain/entities/leave_balance.dart';
import 'package:hr_core/features/leave/domain/entities/leave_request.dart';
import 'package:hr_core/features/leave/domain/entities/team_leave_entry.dart';
import 'package:hr_core/features/leave/domain/repositories/leave_repository.dart';
import 'package:hr_web/features/leave_management/presentation/bloc/leave_management_cubit.dart';
import 'package:hr_web/features/leave_management/presentation/pages/leave_management_screen.dart';

class MockLeaveRepository implements LeaveRepository {
  bool shouldSucceed = true;
  String? errorMessage;
  LeavePolicy? createdPolicy;

  @override
  Future<bool> createPolicy(LeavePolicy policy) async {
    createdPolicy = policy;
    if (!shouldSucceed) {
      throw StateError(errorMessage ?? 'Backend error creating policy');
    }
    return true;
  }

  @override
  Future<List<LeavePolicy>> getPolicies() async => [
        if (createdPolicy != null) createdPolicy!,
      ];

  @override
  Future<List<LeaveBalance>> getBalances() async => [];

  @override
  Future<List<LeaveRequest>> getMyRequests() async => [];

  @override
  Future<void> applyLeave(LeaveRequest draft) async {}

  @override
  Future<void> cancelRequest(String id) async {}

  @override
  Future<void> cancelRequestWithReason(String id, String reason) async {}

  @override
  Future<List<TeamLeaveEntry>> getTeamCalendar() async => [];

  @override
  Future<void> requestEncashment(LeaveType type, int days) async {}

  @override
  Future<void> advanceApprovalStep(String requestId) async {}

  @override
  Future<List<LeaveRequest>> getPendingApprovals(ApprovalScope scope) async => [];

  @override
  Future<void> approveRequest(String requestId) async {}

  @override
  Future<void> approveRequestWithComment(String requestId, String? comment) async {}

  @override
  Future<void> rejectRequest(String requestId) async {}

  @override
  Future<void> rejectRequestWithComment(String requestId, String comment) async {}

  @override
  Future<void> updatePolicy(LeaveType type, Map<String, dynamic> data) async {}

  @override
  Future<void> togglePolicy(LeaveType type) async {}

  @override
  Future<Map<String, dynamic>> getBalancesAdmin({
    required int page,
    required int limit,
    String? employeeId,
    String? department,
    String? branchId,
    int? year,
  }) async => {
        'total': 0,
        'page': page,
        'limit': limit,
        'totalPages': 1,
        'items': <LeaveBalance>[],
      };

  @override
  Future<void> createBalance({
    required String userId,
    required LeaveType type,
    required int year,
    required double entitledDays,
  }) async {}

  @override
  Future<void> adjustBalance({
    required String balanceId,
    required double adjustmentDays,
    required String reason,
  }) async {}

  @override
  Future<Map<String, dynamic>> getCompanyApprovalConfig() async => {'configured': false};

  @override
  Future<void> updateCompanyApprovalConfig(String? finalHrApproverId) async {}

  @override
  Future<Map<String, dynamic>> previewLeave({
    required LeaveType type,
    required DateTime startDate,
    required DateTime endDate,
    required bool isHalfDay,
    String? halfDayPeriod,
    required String reason,
  }) async => {};

  @override
  Future<List<Map<String, dynamic>>> getEmployeesForPicker() async => [];
}

void main() {
  group('LeavePolicyFormDialog Widget Tests', () {
    late MockLeaveRepository mockRepo;
    late LeaveManagementCubit cubit;

    setUp(() {
      mockRepo = MockLeaveRepository();
      cubit = LeaveManagementCubit(mockRepo);
      // Initialize cubit state as Loaded
      cubit.emit(const LeaveManagementLoaded(
        policies: [],
        balances: [],
        pendingRequests: [],
        config: {'configured': false},
        employees: [],
        totalBalances: 0,
        currentBalancesPage: 1,
        totalBalancesPages: 1,
      ));
    });

    Widget createTestableWidget(Widget child) {
      return MaterialApp(
        home: Scaffold(
          body: child,
        ),
      );
    }

    testWidgets('invalid inputs show visible validation errors and block save',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget(
        LeavePolicyFormDialog(cubit: cubit),
      ));

      // Leave fields empty and tap save
      final saveButton = find.widgetWithText(ElevatedButton, 'save');
      expect(saveButton, findsOneWidget);

      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Validation errors should be displayed
      expect(find.text('display_name_required'), findsOneWidget);
      expect(find.text('invalid_entitlement'), findsOneWidget);
      expect(find.text('invalid_notice_days'), findsOneWidget);

      // Repo should not have received createPolicy call
      expect(mockRepo.createdPolicy, isNull);
    });

    testWidgets('valid inputs submit policy and close dialog on success',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget(
        LeavePolicyFormDialog(cubit: cubit),
      ));

      // Fill in valid inputs
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'إجازة جديدة');
      await tester.enterText(textFields.at(1), '21');
      await tester.enterText(textFields.at(2), '3');

      final saveButton = find.widgetWithText(ElevatedButton, 'save');
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Should have created policy and closed dialog
      expect(mockRepo.createdPolicy, isNotNull);
      expect(mockRepo.createdPolicy!.displayNameAr, equals('إجازة جديدة'));
      expect(mockRepo.createdPolicy!.annualEntitlement, equals(21.0));
      expect(mockRepo.createdPolicy!.minimumNoticeDays, equals(3));
      expect(find.byType(LeavePolicyFormDialog), findsNothing);
    });

    testWidgets('failed save displays server error and returns to enabled state',
        (WidgetTester tester) async {
      mockRepo.shouldSucceed = false;
      mockRepo.errorMessage = 'POLICY_NOT_FOUND_OR_INACTIVE';

      await tester.pumpWidget(createTestableWidget(
        LeavePolicyFormDialog(cubit: cubit),
      ));

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'إجازة سنوية');
      await tester.enterText(textFields.at(1), '14');
      await tester.enterText(textFields.at(2), '0');

      final saveButton = find.widgetWithText(ElevatedButton, 'save');
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Dialog remains open, displaying mapped server error
      expect(find.byType(LeavePolicyFormDialog), findsOneWidget);
      expect(find.text('سياسة الإجازة غير موجودة أو غير نشطة حالياً.'), findsOneWidget);

      // Text fields remain enabled with previous text
      expect(find.text('إجازة سنوية'), findsOneWidget);
    });
  });
}
