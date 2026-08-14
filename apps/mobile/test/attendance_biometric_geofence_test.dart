import 'package:flutter_test/flutter_test.dart';
import 'package:hr_app_demo/core/services/biometric_service.dart';
import 'package:hr_app_demo/core/services/location_service.dart';
import 'package:hr_app_demo/features/attendance/presentation/bloc/attendance_cubit.dart';
import 'package:hr_app_demo/features/attendance/presentation/bloc/attendance_state.dart';
import 'package:hr_core/features/attendance/domain/entities/attendance_enums.dart';
import 'package:hr_core/features/attendance/domain/entities/attendance_record.dart';
import 'package:hr_core/features/attendance/domain/entities/overtime_request.dart';
import 'package:hr_core/features/attendance/domain/entities/shift_info.dart';
import 'package:hr_core/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class MockBiometricService implements BiometricService {
  bool available = true;
  bool authResult = true;
  int authCallCount = 0;
  String? lastReason;

  @override
  Future<bool> isBiometricAvailable() async => available;

  @override
  Future<bool> authenticateBiometricOnly(String reason) async {
    authCallCount++;
    lastReason = reason;
    return authResult;
  }
}

class MockLocationService implements LocationService {
  bool enabled = true;
  bool permission = true;
  LocationFix? currentFix =
      const LocationFix(lat: 24.7136, lng: 46.6753, accuracy: 10);
  int fixCallCount = 0;

  @override
  Future<bool> isLocationServiceEnabled() async => enabled;

  @override
  Future<bool> requestPermission() async => permission;

  @override
  Future<LocationFix?> getCurrentPosition() async {
    fixCallCount++;
    return currentFix;
  }
}

class MockAttendanceRepository implements AttendanceRepository {
  GeofenceStatus preflightResult = const GeofenceStatus(
    withinRange: true,
    distanceMeters: 50,
    allowedRadiusMeters: 200,
    nearestBranch: 'Main Office',
  );
  int preflightCallCount = 0;
  int clockInCallCount = 0;
  double? lastPreflightLat;
  double? lastPreflightLng;
  double? lastPreflightAccuracy;
  double? lastClockInLat;
  double? lastClockInLng;
  double? lastClockInAccuracy;

  AttendanceRecord todayRecord = AttendanceRecord(
    date: DateTime(2026, 8, 14),
    status: AttendanceStatus.none,
    locationLabel: 'none',
  );

  @override
  Future<AttendanceRecord> getTodayStatus() async => todayRecord;

  @override
  Future<GeofenceStatus> preflightGeofence({
    required double lat,
    required double lng,
    required double accuracy,
  }) async {
    preflightCallCount++;
    lastPreflightLat = lat;
    lastPreflightLng = lng;
    lastPreflightAccuracy = accuracy;
    return preflightResult;
  }

  @override
  Future<AttendanceRecord> clockIn({
    required AttendanceStatus mode,
    required double lat,
    required double lng,
    required double accuracy,
  }) async {
    clockInCallCount++;
    lastClockInLat = lat;
    lastClockInLng = lng;
    lastClockInAccuracy = accuracy;
    todayRecord = AttendanceRecord(
      date: DateTime(2026, 8, 14),
      clockInTime: DateTime(2026, 8, 14, 9, 0),
      status: mode,
      locationLabel: 'Main Office',
    );
    return todayRecord;
  }

  @override
  Future<void> clockOut() async {}
  @override
  Future<List<AttendanceRecord>> getHistory() async => [];
  @override
  Future<ShiftInfo> getShift() async => ShiftInfo(
        name: 'Standard',
        startTime: DateTime(2026, 8, 14, 9, 0),
        endTime: DateTime(2026, 8, 14, 17, 0),
      );
  @override
  Future<void> requestOvertime(double hours, String reason) async {}
  @override
  Future<List<OvertimeRequest>> getOvertimeRequests() async => [];
  @override
  Future<void> updateTodayMode(AttendanceStatus mode) async {}
  @override
  Future<void> startBreak() async {}
  @override
  Future<void> endBreak() async {}
}

class MockSocket implements io.Socket {
  @override
  dynamic Function() on(String event, dynamic Function(dynamic) handler) {
    return () {};
  }

  @override
  io.Socket off(String event, [dynamic Function(dynamic)? handler]) {
    return this;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Attendance Biometric Geofence Mobile Flow Verification', () {
    late MockAttendanceRepository repo;
    late MockBiometricService biometric;
    late MockLocationService location;
    late AttendanceCubit cubit;

    setUp(() {
      repo = MockAttendanceRepository();
      biometric = MockBiometricService();
      location = MockLocationService();
      cubit = AttendanceCubit(repo, MockSocket());
    });

    tearDown(() {
      cubit.close();
    });

    test('1. Location preflight requires lat, lng, and accuracy and calls server API',
        () async {
      final res = await cubit.preflightGeofence(
        lat: 24.7136,
        lng: 46.6753,
        accuracy: 10.0,
      );

      expect(res.outcome, equals(PreflightOutcome.inRange));
      expect(repo.preflightCallCount, equals(1));
      expect(repo.lastPreflightLat, equals(24.7136));
      expect(repo.lastPreflightLng, equals(46.6753));
      expect(repo.lastPreflightAccuracy, equals(10.0));
      expect(repo.clockInCallCount, equals(0)); // Preflight does NOT call clockIn
    });

    test('2. Outside range preflight returns outOfRange outcome — no clockIn called',
        () async {
      repo.preflightResult = const GeofenceStatus(
        withinRange: false,
        distanceMeters: 600,
        allowedRadiusMeters: 200,
        nearestBranch: 'Main Office',
      );

      final res = await cubit.preflightGeofence(
        lat: 24.7190,
        lng: 46.6753,
        accuracy: 10.0,
      );

      expect(res.outcome, equals(PreflightOutcome.outOfRange));
      expect(repo.clockInCallCount, equals(0)); // NO clockIn call when outside range
    });

    test('3. BiometricService options force biometricOnly: true', () async {
      final isAvailable = await biometric.isBiometricAvailable();
      expect(isAvailable, isTrue);

      final authenticated = await biometric
          .authenticateBiometricOnly('Please authenticate biometric to clock in');
      expect(authenticated, isTrue);
      expect(biometric.authCallCount, equals(1));
      expect(biometric.lastReason, contains('biometric'));
    });

    test('4. Successful clockIn returns persisted record and updates AttendanceLoaded state',
        () async {
      await cubit.loadAttendanceData();
      expect(cubit.state, isA<AttendanceLoaded>());

      final record = await cubit.clockIn(
        lat: 24.7136,
        lng: 46.6753,
        accuracy: 10.0,
      );

      expect(record, isNotNull);
      expect(record!.locationLabel, equals('Main Office'));
      expect(repo.clockInCallCount, equals(1));
      expect(repo.lastClockInLat, equals(24.7136));
      expect(repo.lastClockInLng, equals(46.6753));
      expect(repo.lastClockInAccuracy, equals(10.0));

      final loadedState = cubit.state as AttendanceLoaded;
      expect(loadedState.todayStatus.clockInTime, isNotNull);
      expect(loadedState.isCheckingIn, isFalse);
    });

    test('5. isCheckingIn guard prevents double-tap / concurrent clockIn calls',
        () async {
      await cubit.loadAttendanceData();

      // Initiate clockIn
      final future1 = cubit.clockIn(lat: 24.7136, lng: 46.6753, accuracy: 10.0);

      // Concurrent second clockIn during in-flight state
      final future2 = cubit.clockIn(lat: 24.7136, lng: 46.6753, accuracy: 10.0);

      final res1 = await future1;
      final res2 = await future2;

      expect(res1, isNotNull);
      expect(res2, isNull); // Second call rejected by isCheckingIn guard
      expect(repo.clockInCallCount, equals(1)); // Exactly ONE call
    });

    test('6. LocationService provides fresh location fix with finite coordinates',
        () async {
      final fix = await location.getCurrentPosition();
      expect(fix, isNotNull);
      expect(fix!.lat.isFinite, isTrue);
      expect(fix.lng.isFinite, isTrue);
      expect(fix.accuracy, greaterThan(0));
    });
  });
}
