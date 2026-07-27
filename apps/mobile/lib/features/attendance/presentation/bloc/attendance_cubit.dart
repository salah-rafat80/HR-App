import 'dart:math' as math;
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

  AttendanceCubit(this._repository, this._socket, this._configRepo) : super(AttendanceInitial()) {
    _socket.on('entity.updated', (data) {
      if (data['type'] == 'AttendanceRecord') {
        loadAttendanceData();
      }
    });
  }

  Future<void> loadAttendanceData() async {
    if (!isClosed) {
      emit(AttendanceLoading());
    }
    try {
      var today = await _repository.getTodayStatus();
      final history = await _repository.getHistory();
      final shift = await _repository.getShift();

      if (!isClosed) {
        emit(
          AttendanceLoaded(todayStatus: today, history: history, shift: shift),
        );
      }
    } catch (e) {
      if (!isClosed) {
        emit(AttendanceError(e.toString()));
      }
    }
  }

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
      if (!isClosed) {
        emit(AttendanceError(e.toString()));
      }
      // Revert to loaded state after error so user can try again
      loadAttendanceData();
    }
  }

  /// Pure client-side Haversine check — no backend call.
  /// The backend will STILL independently enforce the geofence on clockIn.
  Future<GeofenceStatus> checkGeofence(double lat, double lng, {bool forceRefresh = false}) async {
    // Fetch branches if not loaded or if forceRefresh is true
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

      final distance = _calculateHaversineDistance(lat, lng, branch.latitude, branch.longitude);
      
      if (distance < minDistance) {
        minDistance = distance;
        allowedRadius = branch.radiusMeters.toDouble();
        nearestBranchName = branch.name;
      }

      if (distance <= branch.radiusMeters) {
        withinRange = true;
      }
    }

    return GeofenceStatus(
      withinRange: withinRange,
      distanceMeters: minDistance,
      allowedRadiusMeters: allowedRadius,
      locationLabel: nearestBranchName, // Pass nearest branch to UI
    );
  }


  double _calculateHaversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // metres
    final double dLat = _toRad(lat2 - lat1);
    final double dLng = _toRad(lon2 - lon1);
    final double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRad(double deg) => deg * math.pi / 180;

  Future<void> clockOut() async {
    if (state is! AttendanceLoaded) return;

    try {
      await _repository.clockOut();
      final updatedToday = await _repository.getTodayStatus();
      if (!isClosed) {
        emit((state as AttendanceLoaded).copyWith(todayStatus: updatedToday));
      }
    } catch (e) {
      // Handle error
    }
  }
}
