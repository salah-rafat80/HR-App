import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:hr_app_demo/core/utils/safe_cubit.dart';
import 'attendance_state.dart';
import 'package:hr_core/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:hr_core/features/attendance/domain/entities/attendance_enums.dart';
import 'package:hr_core/features/admin/domain/repositories/system_config_repository.dart';
import 'package:hr_core/features/admin/domain/entities/system_config_entities.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class AttendanceCubit extends SafeCubit<AttendanceState> {
  final AttendanceRepository _repository;
  final io.Socket _socket;
  final SystemConfigRepository _configRepo;

  List<OfficeBranch>? _branchesCache;

  /// Stashed state used exclusively by [retryClockOut].
  /// State stays [AttendanceError] until user explicitly retries.
  AttendanceLoaded? _clockOutRetryState;

  AttendanceCubit(this._repository, this._socket, this._configRepo)
      : super(AttendanceInitial()) {
    _socket.on('entity.updated', (data) {
      if (data['type'] == 'AttendanceRecord') {
        loadAttendanceData();
      }
    });
  }

  // ── Data Loading ────────────────────────────────────────────────────────────

  Future<void> loadAttendanceData() async {
    emit(AttendanceLoading());
    try {
      final today = await _repository.getTodayStatus();
      final history = await _repository.getHistory();
      final shift = await _repository.getShift();
      final overtimeRequests = await _repository.getOvertimeRequests();

      emit(AttendanceLoaded(
        todayStatus: today,
        history: history,
        shift: shift,
        overtimeRequests: overtimeRequests,
      ));
    } catch (e) {
      debugPrint('[AttendanceCubit] loadAttendanceData failed: $e');
      emit(const AttendanceError('load_failed'));
    }
  }

  // ── Clock In ────────────────────────────────────────────────────────────────

  Future<void> clockIn({
    required String locationLabel,
    double? lat,
    double? lng,
    double? accuracy,
  }) async {
    if (state is! AttendanceLoaded) return;

    try {
      await _repository.clockIn(
        locationLabel: locationLabel,
        mode: AttendanceStatus.present,
        lat: lat,
        lng: lng,
        accuracy: accuracy,
      );
      final updatedToday = await _repository.getTodayStatus();
      if (!isClosed) {
        emit((state as AttendanceLoaded).copyWith(todayStatus: updatedToday));
      }
    } catch (e) {
      debugPrint('[AttendanceCubit] clockIn failed: $e');
      emit(const AttendanceError('clock_in_failed'));
      loadAttendanceData();
    }
  }

  // ── Clock Out (P2 — real error state, user-driven retry) ────────────────────

  Future<void> clockOut() async {
    if (state is! AttendanceLoaded) return;
    final previousState = state as AttendanceLoaded;

    try {
      await _repository.clockOut();
      final updatedToday = await _repository.getTodayStatus();
      _clockOutRetryState = null;
      if (!isClosed) {
        emit(previousState.copyWith(todayStatus: updatedToday));
      }
    } catch (e) {
      // Log technical details internally — never expose raw exception to user
      debugPrint('[AttendanceCubit] clockOut failed: $e');
      // Stash previous state so retryClockOut can restore and retry
      _clockOutRetryState = previousState;
      // State stays Error until user explicitly presses Retry — no auto-revert timer
      emit(const AttendanceError('clock_out_failed'));
    }
  }

  /// Called from the "Retry" SnackBarAction — user-initiated, not timer-driven.
  Future<void> retryClockOut() async {
    if (_clockOutRetryState == null) return;
    emit(_clockOutRetryState!);
    await clockOut();
  }

  // ── Geofence (client-side Haversine) ────────────────────────────────────────

  Future<GeofenceStatus> checkGeofence(double lat, double lng,
      {bool forceRefresh = false}) async {
    if (_branchesCache == null || forceRefresh) {
      try {
        _branchesCache = await _configRepo.getBranches();
      } catch (e) {
        _branchesCache ??= [];
      }
    }

    if (_branchesCache!.isEmpty) {
      return const GeofenceStatus(
        withinRange: false,
        distanceMeters: 999999,
        allowedRadiusMeters: 0,
      );
    }

    double minDistance = double.infinity;
    bool withinRange = false;
    double allowedRadius = 0;
    String? nearestBranchName;

    for (final branch in _branchesCache!) {
      if (!branch.isActive) continue;
      final distance =
          _calculateHaversineDistance(lat, lng, branch.latitude, branch.longitude);
      if (distance < minDistance) {
        minDistance = distance;
        allowedRadius = branch.radiusMeters.toDouble();
        nearestBranchName = branch.name;
      }
      if (distance <= branch.radiusMeters) withinRange = true;
    }

    return GeofenceStatus(
      withinRange: withinRange,
      distanceMeters: minDistance,
      allowedRadiusMeters: allowedRadius,
      locationLabel: nearestBranchName,
    );
  }

  double _calculateHaversineDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000;
    final double dLat = _toRad(lat2 - lat1);
    final double dLng = _toRad(lon2 - lon1);
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRad(double deg) => deg * math.pi / 180;

  // ── Overtime (P1 — real submit + reload list) ────────────────────────────────

  Future<void> submitOvertime(double hours, String reason) async {
    if (state is! AttendanceLoaded) return;
    final currentState = state as AttendanceLoaded;

    // Disable submit button while in flight
    emit(currentState.copyWith(isSubmittingOvertime: true));

    try {
      await _repository.requestOvertime(hours, reason);
      final updatedRequests = await _repository.getOvertimeRequests();
      if (!isClosed) {
        emit(currentState.copyWith(
          isSubmittingOvertime: false,
          overtimeRequests: updatedRequests,
        ));
      }
    } catch (e) {
      debugPrint('[AttendanceCubit] submitOvertime failed: $e');
      if (!isClosed) {
        emit(currentState.copyWith(isSubmittingOvertime: false));
        // Surface error back to UI via a separate state so BlocListener can react
        emit(const AttendanceError('overtime_submit_failed'));
        // Restore loaded state immediately so the tab doesn't get stuck
        emit(currentState.copyWith(isSubmittingOvertime: false));
      }
    }
  }

  // ── WFH Toggle (P5 — PATCH today mode, NOT a new clockIn) ───────────────────

  Future<void> toggleWfh() async {
    if (state is! AttendanceLoaded) return;
    final currentState = state as AttendanceLoaded;
    final newIsWfh = !currentState.isWfh;
    final newMode = newIsWfh ? AttendanceStatus.workFromHome : AttendanceStatus.present;

    // Optimistic UI update
    emit(currentState.copyWith(isWfh: newIsWfh));

    try {
      await _repository.updateTodayMode(newMode);
      final updatedToday = await _repository.getTodayStatus();
      if (!isClosed) {
        emit((state as AttendanceLoaded).copyWith(todayStatus: updatedToday));
      }
    } catch (e) {
      debugPrint('[AttendanceCubit] toggleWfh failed: $e');
      // Revert optimistic update on failure
      if (!isClosed) emit(currentState);
    }
  }

  // ── Break Tracker (P5) ───────────────────────────────────────────────────────

  Future<void> startBreak() async {
    if (state is! AttendanceLoaded) return;
    final currentState = state as AttendanceLoaded;

    // Optimistic UI update
    emit(currentState.copyWith(isOnBreak: true, breakStartTime: DateTime.now()));

    try {
      await _repository.startBreak();
    } catch (e) {
      debugPrint('[AttendanceCubit] startBreak failed: $e');
      if (!isClosed) emit(currentState);
    }
  }

  Future<void> endBreak() async {
    if (state is! AttendanceLoaded) return;
    final currentState = state as AttendanceLoaded;

    // Optimistic UI update
    emit(currentState.copyWith(isOnBreak: false, clearBreakTime: true));

    try {
      await _repository.endBreak();
    } catch (e) {
      debugPrint('[AttendanceCubit] endBreak failed: $e');
      if (!isClosed) emit(currentState);
    }
  }
}
