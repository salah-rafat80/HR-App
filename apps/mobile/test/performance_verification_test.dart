import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:hr_core/features/home/domain/entities/home_entities.dart';
import 'package:hr_core/features/home/domain/repositories/home_repository.dart';
import 'package:hr_core/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:hr_core/features/attendance/domain/entities/attendance_record.dart';
import 'package:hr_core/features/attendance/domain/entities/attendance_enums.dart';
import 'package:hr_core/features/attendance/domain/entities/shift_info.dart';
import 'package:hr_core/features/attendance/domain/entities/overtime_request.dart';
import 'package:hr_core/features/leave/domain/repositories/leave_repository.dart';
import 'package:hr_core/features/leave/domain/entities/leave_balance.dart';
import 'package:hr_core/features/leave/domain/entities/leave_request.dart';
import 'package:hr_core/features/kpi/domain/repositories/kpi_repository.dart';
import 'package:hr_core/features/training/domain/repositories/training_repository.dart';
import 'package:hr_core/features/training/domain/entities/training_entities.dart';
import 'package:hr_core/features/admin/domain/repositories/system_config_repository.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import 'package:hr_app_demo/features/home/presentation/bloc/home_cubit.dart';
import 'package:hr_app_demo/features/home/presentation/bloc/home_state.dart';
import 'package:hr_app_demo/features/attendance/presentation/bloc/attendance_cubit.dart';
import 'package:hr_app_demo/features/attendance/presentation/bloc/attendance_state.dart';

// ── Mock Repositories with Timestamps & Latency Tracking ──────────────────────

class RequestLog {
  final String name;
  final DateTime startTime;
  DateTime? endTime;

  RequestLog(this.name, this.startTime);
}

class MockHomeRepository implements HomeRepository {
  final Duration delay;
  final bool shouldFail;
  final List<RequestLog> logs = [];

  MockHomeRepository({this.delay = const Duration(milliseconds: 100), this.shouldFail = false});

  @override
  Future<HomeDashboardData> getDashboardData() async {
    final start = DateTime.now();
    final log = RequestLog('getDashboardData', start);
    logs.add(log);
    await Future.delayed(delay);
    if (shouldFail) throw Exception('Dashboard Network Error');
    log.endTime = DateTime.now();
    return HomeDashboardData(
      employeeName: 'Test User',
      todayDate: DateTime.now(),
      leaveDaysLeft: 10,
      leaveDaysTotal: 21,
      kpiScorePercent: 85.0,
      announcements: [],
      birthdaysToday: [],
      upcomingHolidays: [],
      pendingMandatoryTrainingCount: 1,
    );
  }
}

class MockAttendanceRepository implements AttendanceRepository {
  final Duration delay;
  final bool shouldFailToday;
  final bool shouldFailHistory;
  final List<RequestLog> logs = [];

  MockAttendanceRepository({
    this.delay = const Duration(milliseconds: 100),
    this.shouldFailToday = false,
    this.shouldFailHistory = false,
  });

  @override
  Future<AttendanceRecord> getTodayStatus() async {
    final start = DateTime.now();
    final log = RequestLog('getTodayStatus', start);
    logs.add(log);
    await Future.delayed(delay);
    if (shouldFailToday) throw Exception('Today Status Network Error');
    log.endTime = DateTime.now();
    return AttendanceRecord(
      date: DateTime.now(),
      status: AttendanceStatus.present,
      locationLabel: 'Main Office',
    );
  }

  @override
  Future<List<AttendanceRecord>> getHistory() async {
    final start = DateTime.now();
    final log = RequestLog('getHistory', start);
    logs.add(log);
    await Future.delayed(delay);
    if (shouldFailHistory) throw Exception('History Network Error');
    log.endTime = DateTime.now();
    return [];
  }

  @override
  Future<ShiftInfo> getShift() async {
    final start = DateTime.now();
    final log = RequestLog('getShift', start);
    logs.add(log);
    await Future.delayed(delay);
    log.endTime = DateTime.now();
    return ShiftInfo(name: 'Morning Shift', startTime: DateTime.now(), endTime: DateTime.now());
  }

  @override
  Future<List<OvertimeRequest>> getOvertimeRequests() async {
    final start = DateTime.now();
    final log = RequestLog('getOvertimeRequests', start);
    logs.add(log);
    await Future.delayed(delay);
    log.endTime = DateTime.now();
    return [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockLeaveRepository implements LeaveRepository {
  final Duration delay;
  final bool shouldFail;
  final List<RequestLog> logs = [];

  MockLeaveRepository({this.delay = const Duration(milliseconds: 100), this.shouldFail = false});

  @override
  Future<List<LeaveBalance>> getBalances() async {
    final start = DateTime.now();
    final log = RequestLog('getBalances', start);
    logs.add(log);
    await Future.delayed(delay);
    if (shouldFail) throw Exception('Balances Network Error');
    log.endTime = DateTime.now();
    return [];
  }

  @override
  Future<List<LeaveRequest>> getMyRequests() async {
    final start = DateTime.now();
    final log = RequestLog('getMyRequests', start);
    logs.add(log);
    await Future.delayed(delay);
    log.endTime = DateTime.now();
    return [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockKpiRepository implements KpiRepository {
  final Duration delay;
  final List<RequestLog> logs = [];

  MockKpiRepository({this.delay = const Duration(milliseconds: 100)});

  @override
  Future<double> getOverallQuarterScore() async {
    final start = DateTime.now();
    final log = RequestLog('getOverallQuarterScore', start);
    logs.add(log);
    await Future.delayed(delay);
    log.endTime = DateTime.now();
    return 90.0;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockTrainingRepository implements TrainingRepository {
  final Duration delay;
  final List<RequestLog> logs = [];

  MockTrainingRepository({this.delay = const Duration(milliseconds: 100)});

  @override
  Future<List<TrainingCourse>> getPendingMandatoryCourses() async {
    final start = DateTime.now();
    final log = RequestLog('getPendingMandatoryCourses', start);
    logs.add(log);
    await Future.delayed(delay);
    log.endTime = DateTime.now();
    return [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockSocket implements io.Socket {
  final Map<String, List<Function>> _listeners = {};

  @override
  dynamic Function() on(String event, dynamic Function(dynamic) handler) {
    _listeners.putIfAbsent(event, () => []).add(handler);
    return () {};
  }

  @override
  io.Socket off(String event, [dynamic Function(dynamic)? handler]) {
    if (handler != null) {
      _listeners[event]?.remove(handler);
    } else {
      _listeners.remove(event);
    }
    return this;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockSystemConfigRepository implements SystemConfigRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('F-003: Home Dashboard Concurrency & Overlap Measurement', () {
    test('Verify actual request overlap and measure execution timing', () async {
      final homeRepo = MockHomeRepository(delay: const Duration(milliseconds: 100));
      final attRepo = MockAttendanceRepository(delay: const Duration(milliseconds: 100));
      final leaveRepo = MockLeaveRepository(delay: const Duration(milliseconds: 100));
      final kpiRepo = MockKpiRepository(delay: const Duration(milliseconds: 100));
      final trainingRepo = MockTrainingRepository(delay: const Duration(milliseconds: 100));

      final cubit = HomeCubit(homeRepo, attRepo, leaveRepo, kpiRepo, trainingRepo);

      final totalStart = DateTime.now();
      await cubit.loadDashboard();
      final totalEnd = DateTime.now();
      final totalMs = totalEnd.difference(totalStart).inMilliseconds;

      final allLogs = [
        ...homeRepo.logs,
        ...attRepo.logs,
        ...leaveRepo.logs,
        ...kpiRepo.logs,
        ...trainingRepo.logs,
      ];

      print('\n=== HOME DASHBOARD EMPIRICAL MEASUREMENT ===');
      print('Total Dashboard Load Time: ${totalMs}ms');
      print('Total Requests Dispatched: ${allLogs.length}');
      for (final log in allLogs) {
        print('  - ${log.name}: Start at ${log.startTime.millisecondsSinceEpoch}ms, End at ${log.endTime?.millisecondsSinceEpoch}ms');
      }

      // Concurrency Proof: Second request must start BEFORE first request finishes
      final firstEnd = homeRepo.logs.first.endTime!;
      final secondStart = attRepo.logs.first.startTime;

      expect(secondStart.isBefore(firstEnd), isTrue, reason: 'Request 2 started before Request 1 completed (Overlap verified!)');
      expect(totalMs, lessThan(350), reason: '6 x 100ms requests completed concurrently in <350ms instead of ~600ms sequential waterfall');
      expect(cubit.state, isA<HomeLoaded>());
    });

    test('Verify single request failure in Home suppresses dashboard render safely', () async {
      final homeRepo = MockHomeRepository();
      final attRepo = MockAttendanceRepository();
      final leaveRepo = MockLeaveRepository(shouldFail: true); // Leave fails
      final kpiRepo = MockKpiRepository();
      final trainingRepo = MockTrainingRepository();

      final cubit = HomeCubit(homeRepo, attRepo, leaveRepo, kpiRepo, trainingRepo);
      await cubit.loadDashboard();

      expect(cubit.state, isA<HomeError>());
    });
  });

  group('F-005: Attendance Concurrency & Overlap Measurement', () {
    test('Verify actual request overlap and measure execution timing', () async {
      final attRepo = MockAttendanceRepository(delay: const Duration(milliseconds: 100));
      final socket = MockSocket();
      final configRepo = MockSystemConfigRepository();

      final cubit = AttendanceCubit(attRepo, socket, configRepo);

      final totalStart = DateTime.now();
      await cubit.loadAttendanceData();
      final totalEnd = DateTime.now();
      final totalMs = totalEnd.difference(totalStart).inMilliseconds;

      print('\n=== ATTENDANCE SCREEN EMPIRICAL MEASUREMENT ===');
      print('Total Attendance Load Time: ${totalMs}ms');
      print('Total Requests Dispatched: ${attRepo.logs.length}');
      for (final log in attRepo.logs) {
        print('  - ${log.name}: Start at ${log.startTime.millisecondsSinceEpoch}ms, End at ${log.endTime?.millisecondsSinceEpoch}ms');
      }

      final firstEnd = attRepo.logs[0].endTime!;
      final secondStart = attRepo.logs[1].startTime;

      expect(secondStart.isBefore(firstEnd), isTrue, reason: 'Request 2 started before Request 1 completed (Overlap verified!)');
      expect(totalMs, lessThan(250), reason: '4 x 100ms requests completed concurrently in <250ms instead of ~400ms sequential waterfall');
      expect(cubit.state, isA<AttendanceLoaded>());
      cubit.close();
    });

    test('Verify request failure in Attendance handles cleanly', () async {
      final attRepo = MockAttendanceRepository(shouldFailToday: true);
      final socket = MockSocket();
      final configRepo = MockSystemConfigRepository();

      final cubit = AttendanceCubit(attRepo, socket, configRepo);
      await cubit.loadAttendanceData();

      expect(cubit.state, isA<AttendanceError>());
      cubit.close();
    });
  });

  group('Lifecycle, Leaving Screen & Rapid Refresh Verification', () {
    test('Verify leaving screen while requests in flight does not throw unhandled exception', () async {
      final homeRepo = MockHomeRepository(delay: const Duration(milliseconds: 200));
      final attRepo = MockAttendanceRepository(delay: const Duration(milliseconds: 200));
      final leaveRepo = MockLeaveRepository(delay: const Duration(milliseconds: 200));
      final kpiRepo = MockKpiRepository(delay: const Duration(milliseconds: 200));
      final trainingRepo = MockTrainingRepository(delay: const Duration(milliseconds: 200));

      final cubit = HomeCubit(homeRepo, attRepo, leaveRepo, kpiRepo, trainingRepo);

      // Start fetching data
      final future = cubit.loadDashboard();
      // Immediately close cubit (user left screen)
      await cubit.close();

      // Wait for background futures to complete
      await future;

      expect(cubit.isClosed, isTrue);
    });

    test('Verify rapid refresh requests complete without stale state corruption', () async {
      final homeRepo = MockHomeRepository(delay: const Duration(milliseconds: 50));
      final attRepo = MockAttendanceRepository(delay: const Duration(milliseconds: 50));
      final leaveRepo = MockLeaveRepository(delay: const Duration(milliseconds: 50));
      final kpiRepo = MockKpiRepository(delay: const Duration(milliseconds: 50));
      final trainingRepo = MockTrainingRepository(delay: const Duration(milliseconds: 50));

      final cubit = HomeCubit(homeRepo, attRepo, leaveRepo, kpiRepo, trainingRepo);

      // Rapid dual pull-to-refresh
      final f1 = cubit.loadDashboard();
      final f2 = cubit.loadDashboard();

      await Future.wait([f1, f2]);

      expect(cubit.state, isA<HomeLoaded>());
    });
  });
}
