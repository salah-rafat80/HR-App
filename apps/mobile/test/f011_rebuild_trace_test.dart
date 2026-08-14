import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

import 'package:hr_app_demo/features/home/presentation/bloc/home_cubit.dart';
import 'package:hr_app_demo/features/home/presentation/bloc/home_state.dart';

class MockHomeRepository implements HomeRepository {
  @override
  Future<HomeDashboardData> getDashboardData() async {
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
  @override
  Future<AttendanceRecord> getTodayStatus() async {
    return AttendanceRecord(
      date: DateTime.now(),
      status: AttendanceStatus.present,
      locationLabel: 'Office',
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockLeaveRepository implements LeaveRepository {
  @override
  Future<List<LeaveBalance>> getBalances() async => [];
  @override
  Future<List<LeaveRequest>> getMyRequests() async => [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockKpiRepository implements KpiRepository {
  @override
  Future<double> getOverallQuarterScore() async => 90.0;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockTrainingRepository implements TrainingRepository {
  @override
  Future<List<TrainingCourse>> getPendingMandatoryCourses() async => [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('F-011 Audit: Measure HomeCubit state emissions and rebuild count', (tester) async {
    int rebuildCount = 0;
    int stateEmissionCount = 0;

    final cubit = HomeCubit(
      MockHomeRepository(),
      MockAttendanceRepository(),
      MockLeaveRepository(),
      MockKpiRepository(),
      MockTrainingRepository(),
    );

    cubit.stream.listen((_) {
      stateEmissionCount++;
    });

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: Scaffold(
            body: BlocBuilder<HomeCubit, HomeState>(
              buildWhen: (previous, current) => previous.runtimeType != current.runtimeType || previous != current,
              builder: (context, state) {
                rebuildCount++;
                return Text('State: ${state.runtimeType}');
              },
            ),
          ),
        ),
      ),
    );

    expect(rebuildCount, 1); // Initial HomeInitial build

    await cubit.loadDashboard();
    await tester.pumpAndSettle();

    print('\n=== F-011 REBUILD TRACE MEASUREMENT ===');
    print('Total State Emissions: $stateEmissionCount');
    print('Total Widget Rebuilds: $rebuildCount');

    // 1 emission for HomeLoading, 1 emission for HomeLoaded -> 3 total rebuilds for initial load cycle
    expect(stateEmissionCount, 2);
    expect(rebuildCount, 2);
  });
}
