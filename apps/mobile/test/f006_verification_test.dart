import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:hr_core/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:hr_core/features/attendance/domain/entities/attendance_record.dart';
import 'package:hr_core/features/attendance/domain/entities/attendance_enums.dart';
import 'package:hr_core/features/attendance/domain/entities/shift_info.dart';
import 'package:hr_core/features/attendance/domain/entities/overtime_request.dart';
import 'package:hr_core/features/admin/domain/repositories/system_config_repository.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import 'package:hr_app_demo/features/attendance/presentation/bloc/attendance_cubit.dart';

// ── Socket IO Mock for F-006 Verification Audit ─────────────────────────────

class VerificationSocket implements io.Socket {
  final Map<String, List<dynamic Function(dynamic)>> listeners = {};

  int get activeListenerCount => listeners['entity.updated']?.length ?? 0;

  @override
  dynamic Function() on(String event, dynamic Function(dynamic) handler) {
    listeners.putIfAbsent(event, () => []).add(handler);
    return () {};
  }

  @override
  io.Socket off(String event, [dynamic Function(dynamic)? handler]) {
    if (handler != null) {
      listeners[event]?.remove(handler);
      if (listeners[event] != null && listeners[event]!.isEmpty) {
        listeners.remove(event);
      }
    } else {
      listeners.remove(event);
    }
    return this;
  }

  void triggerEvent(String event, dynamic data) {
    final handlers = List<dynamic Function(dynamic)>.from(listeners[event] ?? []);
    for (final h in handlers) {
      h(data);
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class VerificationAttendanceRepository implements AttendanceRepository {
  int getTodayStatusCallCount = 0;

  @override
  Future<AttendanceRecord> getTodayStatus() async {
    getTodayStatusCallCount++;
    return AttendanceRecord(
      date: DateTime.now(),
      status: AttendanceStatus.present,
      locationLabel: 'Office',
    );
  }

  @override
  Future<List<AttendanceRecord>> getHistory() async => [];

  @override
  Future<ShiftInfo> getShift() async => ShiftInfo(name: 'Day', startTime: DateTime.now(), endTime: DateTime.now());

  @override
  Future<List<OvertimeRequest>> getOvertimeRequests() async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class VerificationConfigRepository implements SystemConfigRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('F-006 Verification: Listener Accumulation Test', () {
    test('10 Create -> Close cycles keep active listener count bounded at 0 baseline', () async {
      final repo = VerificationAttendanceRepository();
      final socket = VerificationSocket();
      final config = VerificationConfigRepository();

      expect(socket.activeListenerCount, 0, reason: 'Baseline active listeners should be 0');

      for (int i = 1; i <= 10; i++) {
        final cubit = AttendanceCubit(repo, socket);
        expect(socket.activeListenerCount, 1, reason: 'Iteration $i: Cubit created -> 1 active listener registered');
        await cubit.close();
        expect(socket.activeListenerCount, 0, reason: 'Iteration $i: Cubit closed -> active listener deregistered, count returns to 0');
      }
    });
  });

  group('F-006 Verification: Duplicate Callback & Event Test', () {
    test('Socket event triggers exactly 1 API refresh on active Cubit', () async {
      final repo = VerificationAttendanceRepository();
      final socket = VerificationSocket();
      final config = VerificationConfigRepository();

      final cubit = AttendanceCubit(repo, socket);
      repo.getTodayStatusCallCount = 0;

      // Emit entity.updated event for AttendanceRecord
      socket.triggerEvent('entity.updated', {'type': 'AttendanceRecord'});

      // Wait microtask tick
      await Future.delayed(const Duration(milliseconds: 10));

      expect(repo.getTodayStatusCallCount, 1, reason: 'Exactly 1 API request executed on socket event');
      await cubit.close();
    });

    test('Socket event after Cubit.close() triggers 0 API requests and 0 state emissions', () async {
      final repo = VerificationAttendanceRepository();
      final socket = VerificationSocket();
      final config = VerificationConfigRepository();

      final cubit = AttendanceCubit(repo, socket);
      await cubit.close();

      repo.getTodayStatusCallCount = 0;
      final stateBefore = cubit.state;

      // Emit entity.updated event after close
      socket.triggerEvent('entity.updated', {'type': 'AttendanceRecord'});
      await Future.delayed(const Duration(milliseconds: 10));

      expect(repo.getTodayStatusCallCount, 0, reason: 'Closed Cubit MUST NOT trigger API requests');
      expect(cubit.state, equals(stateBefore), reason: 'Closed Cubit MUST NOT emit state changes');
    });

    test('10 Create -> Close cycles followed by new Cubit produces exactly 1 response', () async {
      final repo = VerificationAttendanceRepository();
      final socket = VerificationSocket();
      final config = VerificationConfigRepository();

      // Cycle 10 historical Cubits
      for (int i = 0; i < 10; i++) {
        final historicalCubit = AttendanceCubit(repo, socket);
        await historicalCubit.close();
      }

      // Create active 11th Cubit
      final activeCubit = AttendanceCubit(repo, socket);
      repo.getTodayStatusCallCount = 0;

      socket.triggerEvent('entity.updated', {'type': 'AttendanceRecord'});
      await Future.delayed(const Duration(milliseconds: 10));

      expect(repo.getTodayStatusCallCount, 1, reason: 'Only the active Cubit responded (0 duplicate requests from 10 closed Cubits)');
      await activeCubit.close();
    });
  });
}
