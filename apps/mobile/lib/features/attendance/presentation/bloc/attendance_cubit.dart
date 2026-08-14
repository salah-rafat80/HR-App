import 'package:flutter/foundation.dart';
import 'package:hr_app_demo/core/utils/safe_cubit.dart';
import 'attendance_state.dart';
import 'package:hr_core/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:hr_core/features/attendance/domain/entities/attendance_enums.dart';
import 'package:hr_core/features/attendance/domain/entities/attendance_record.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

/// Result of the server geofence preflight call.
/// Returned to the widget so it can present distinct UI states before
/// requesting biometric authentication.
enum PreflightOutcome {
  inRange,
  outOfRange,
  gpsDisabled,
  permissionDenied,
  noCurrentFix,
  poorAccuracy,
  serverError,
}

class PreflightResult {
  final PreflightOutcome outcome;
  final String? nearestBranch;
  final double? distanceMeters;
  final double? allowedRadiusMeters;
  final double? lat;
  final double? lng;
  final double? accuracy;

  const PreflightResult({
    required this.outcome,
    this.nearestBranch,
    this.distanceMeters,
    this.allowedRadiusMeters,
    this.lat,
    this.lng,
    this.accuracy,
  });
}

class AttendanceCubit extends SafeCubit<AttendanceState> {
  final AttendanceRepository _repository;
  final io.Socket _socket;

  /// Stashed state used exclusively by [retryClockOut].
  AttendanceLoaded? _clockOutRetryState;

  AttendanceCubit(this._repository, this._socket)
      : super(AttendanceInitial()) {
    _socket.on('entity.updated', _onEntityUpdated);
  }

  void _onEntityUpdated(dynamic data) {
    if (data is Map && data['type'] == 'AttendanceRecord' && !isClosed) {
      // WebSocket is an additional UI refresh only — does NOT set success state.
      loadAttendanceData();
    }
  }

  @override
  Future<void> close() {
    _socket.off('entity.updated', _onEntityUpdated);
    return super.close();
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

  // ── Geofence Preflight ─────────────────────────────────────────────────────

  /// Calls GET /attendance/geofence-status with lat, lng, AND accuracy.
  /// This is the single pre-biometric server check.
  /// The widget calls this once after obtaining a fresh GPS fix.
  Future<PreflightResult> preflightGeofence({
    required double lat,
    required double lng,
    required double accuracy,
  }) async {
    try {
      final status = await _repository.preflightGeofence(
        lat: lat,
        lng: lng,
        accuracy: accuracy,
      );
      if (status.withinRange) {
        return PreflightResult(
          outcome: PreflightOutcome.inRange,
          nearestBranch: status.nearestBranch,
          distanceMeters: status.distanceMeters,
          allowedRadiusMeters: status.allowedRadiusMeters,
          lat: lat,
          lng: lng,
          accuracy: accuracy,
        );
      } else {
        return PreflightResult(
          outcome: PreflightOutcome.outOfRange,
          nearestBranch: status.nearestBranch,
          distanceMeters: status.distanceMeters,
          allowedRadiusMeters: status.allowedRadiusMeters,
        );
      }
    } catch (e) {
      debugPrint('[AttendanceCubit] preflightGeofence error: $e');
      return const PreflightResult(outcome: PreflightOutcome.serverError);
    }
  }

  // ── Clock In ────────────────────────────────────────────────────────────────

  /// Called ONLY after:
  ///   1. A fresh GPS fix was obtained.
  ///   2. [preflightGeofence] returned [PreflightOutcome.inRange].
  ///   3. Biometric authentication succeeded.
  ///
  /// Sends exactly one POST /attendance/clock-in and uses the persisted
  /// [AttendanceRecord] from the server response as the sole source of
  /// truth for the success state.
  Future<AttendanceRecord?> clockIn({
    required double lat,
    required double lng,
    required double accuracy,
  }) async {
    if (state is! AttendanceLoaded) return null;
    final currentState = state as AttendanceLoaded;

    // Guard: prevent double invocation
    if (currentState.isCheckingIn) return null;

    emit(currentState.copyWith(isCheckingIn: true));

    try {
      final persistedRecord = await _repository.clockIn(
        mode: AttendanceStatus.present,
        lat: lat,
        lng: lng,
        accuracy: accuracy,
      );

      if (!isClosed) {
        emit(currentState.copyWith(
          isCheckingIn: false,
          todayStatus: persistedRecord,
        ));
      }
      return persistedRecord;
    } catch (e) {
      debugPrint('[AttendanceCubit] clockIn failed: $e');
      if (!isClosed) {
        emit(currentState.copyWith(isCheckingIn: false));
        emit(const AttendanceError('clock_in_failed'));
        loadAttendanceData();
      }
      return null;
    }
  }

  // ── Clock Out ───────────────────────────────────────────────────────────────

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
      debugPrint('[AttendanceCubit] clockOut failed: $e');
      _clockOutRetryState = previousState;
      emit(const AttendanceError('clock_out_failed'));
    }
  }

  Future<void> retryClockOut() async {
    if (_clockOutRetryState == null) return;
    emit(_clockOutRetryState!);
    await clockOut();
  }

  // ── Overtime ─────────────────────────────────────────────────────────────────

  Future<void> submitOvertime(double hours, String reason) async {
    if (state is! AttendanceLoaded) return;
    final currentState = state as AttendanceLoaded;

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
        emit(const AttendanceError('overtime_submit_failed'));
        emit(currentState.copyWith(isSubmittingOvertime: false));
      }
    }
  }

  // ── WFH Toggle ───────────────────────────────────────────────────────────────

  Future<void> toggleWfh() async {
    if (state is! AttendanceLoaded) return;
    final currentState = state as AttendanceLoaded;
    final newIsWfh = !currentState.isWfh;
    final newMode =
        newIsWfh ? AttendanceStatus.workFromHome : AttendanceStatus.present;

    emit(currentState.copyWith(isWfh: newIsWfh));

    try {
      await _repository.updateTodayMode(newMode);
      final updatedToday = await _repository.getTodayStatus();
      if (!isClosed) {
        emit((state as AttendanceLoaded).copyWith(todayStatus: updatedToday));
      }
    } catch (e) {
      debugPrint('[AttendanceCubit] toggleWfh failed: $e');
      if (!isClosed) emit(currentState);
    }
  }

  // ── Break Tracker ─────────────────────────────────────────────────────────────

  Future<void> startBreak() async {
    if (state is! AttendanceLoaded) return;
    final currentState = state as AttendanceLoaded;

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

    emit(currentState.copyWith(isOnBreak: false, clearBreakTime: true));

    try {
      await _repository.endBreak();
    } catch (e) {
      debugPrint('[AttendanceCubit] endBreak failed: $e');
      if (!isClosed) emit(currentState);
    }
  }
}
