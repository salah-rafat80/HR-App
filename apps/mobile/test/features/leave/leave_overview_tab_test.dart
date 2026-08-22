import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hr_core/core/enums/role_enums.dart';
import 'package:hr_core/features/leave/domain/entities/leave_enums.dart';
import 'package:hr_core/features/leave/domain/entities/leave_balance.dart';
import 'package:hr_core/features/leave/domain/entities/leave_request.dart';
import 'package:hr_core/features/leave/domain/entities/team_leave_entry.dart';
import 'package:hr_core/features/leave/domain/entities/leave_policy.dart';
import 'package:hr_core/features/leave/domain/repositories/leave_repository.dart';
import 'package:hr_app_demo/features/leave/presentation/bloc/leave_cubit.dart';
import 'package:hr_app_demo/features/leave/presentation/widgets/leave_overview_tab.dart';
import 'package:hr_app_demo/features/leave/presentation/widgets/leave_apply_modal.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_it/get_it.dart';

class MockLeaveRepository implements LeaveRepository {
  int previewCallCount = 0;
  List<LeaveBalance> balancesToReturn = [];

  @override
  Future<List<LeaveBalance>> getBalances() async => balancesToReturn;

  @override
  Future<List<LeavePolicy>> getPolicies() async => [];

  @override
  Future<List<LeaveRequest>> getMyRequests() async => [];

  @override
  Future<List<TeamLeaveEntry>> getTeamCalendar() async => [];

  @override
  Future<void> applyLeave(LeaveRequest draft) async {}

  @override
  Future<void> cancelRequest(String id) async {}

  @override
  Future<void> cancelRequestWithReason(String id, String reason) async {}

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
  }) async => {};

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
  Future<Map<String, dynamic>> getCompanyApprovalConfig() async => {};

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
  }) async {
    previewCallCount++;
    return {'workingDays': 2};
  }

  @override
  Future<List<Map<String, dynamic>>> getEmployeesForPicker() async => [];

  @override
  Future<void> createPolicy(LeavePolicy policy) async {}
}

void main() {
  group('Mobile LeaveOverviewTab Widget Tests', () {
    late MockLeaveRepository mockRepo;
    late io.Socket socket;
    late LeaveCubit cubit;

    setUpAll(() async {
      SharedPreferences.setMockInitialValues({'user_id': 'user_123'});
      final prefs = await SharedPreferences.getInstance();
      if (!GetIt.I.isRegistered<SharedPreferences>()) {
        GetIt.I.registerSingleton<SharedPreferences>(prefs);
      }
    });

    setUp(() {
      mockRepo = MockLeaveRepository();
      socket = io.io('http://localhost', io.OptionBuilder().disableAutoConnect().build());
      cubit = LeaveCubit(mockRepo, socket);
    });

    tearDown(() {
      cubit.close();
      socket.dispose();
    });

    Widget buildTestWidget(Widget child) {
      return ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (context, _) => MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: cubit,
              child: child,
            ),
          ),
        ),
      );
    }

    testWidgets('empty backend balances renders localized empty state without static demo cards',
        (WidgetTester tester) async {
      mockRepo.balancesToReturn = [];
      await cubit.loadData();

      await tester.pumpWidget(buildTestWidget(const LeaveOverviewTab()));
      await tester.pumpAndSettle();

      // No hardcoded 18, 9, 5 static demo cards
      expect(find.text('18 days'), findsNothing);
      expect(find.text('9 days'), findsNothing);
      expect(find.text('5 days'), findsNothing);

      // Localized empty state is rendered
      expect(find.text('no_balances_configured_hr'), findsOneWidget);
    });

    testWidgets('real backend balances render exclusively without static demo cards',
        (WidgetTester tester) async {
      mockRepo.balancesToReturn = const [
        LeaveBalance(
          type: LeaveType.annual,
          daysUsed: 2,
          daysTotal: 21,
          entitledDays: 21,
          usedDays: 2,
        ),
      ];
      await cubit.loadData();

      await tester.pumpWidget(buildTestWidget(const LeaveOverviewTab()));
      await tester.pumpAndSettle();

      // Renders real balance: 19.0 days
      expect(find.text('19.0 days'), findsOneWidget);
      expect(find.text('no_balances_configured_hr'), findsNothing);
    });

    testWidgets('opening LeaveApplyModal debounces preview calls and prevents rapid spammed requests',
        (WidgetTester tester) async {
      await cubit.loadData();
      await tester.pumpWidget(buildTestWidget(const LeaveApplyModal()));

      // Immediately after opening, debouncing timer hasn't fired yet
      expect(mockRepo.previewCallCount, equals(0));

      // Pump 200ms - still not fired (debounce duration is 500ms)
      await tester.pump(const Duration(milliseconds: 200));
      expect(mockRepo.previewCallCount, equals(0));

      // Fast forward past 500ms debounce
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Fired exactly once
      expect(mockRepo.previewCallCount, equals(1));
    });
  });
}
