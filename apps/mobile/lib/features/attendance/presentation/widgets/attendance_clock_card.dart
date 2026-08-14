import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hr_core/features/attendance/domain/entities/attendance_record.dart';
import 'package:hr_core/features/attendance/domain/entities/attendance_enums.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/biometric_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/attendance_cubit.dart';
import '../bloc/attendance_state.dart';
import 'package:hr_app_demo/core/widgets/app_loader.dart';
import '../../../../core/widgets/app_card.dart';
import 'components/live_clock.dart';
import 'components/animated_clock_button.dart';
import 'components/location_status_indicator.dart';
import 'components/today_attendance_summary.dart';

class AttendanceClockCard extends StatefulWidget {
  final BiometricService? biometricService;
  final LocationService? locationService;

  const AttendanceClockCard({
    super.key,
    this.biometricService,
    this.locationService,
  });

  @override
  State<AttendanceClockCard> createState() => _AttendanceClockCardState();
}

class _AttendanceClockCardState extends State<AttendanceClockCard> {
  bool _isLoadingLocation = false;
  GeofenceStatus? _geofenceStatus;
  String? _locationError;
  bool _justClockedIn = false;

  late final BiometricService _biometric =
      widget.biometricService ?? getIt<BiometricService>();
  late final LocationService _location =
      widget.locationService ?? getIt<LocationService>();

  @override
  void initState() {
    super.initState();
  }

  // ── Non-authoritative display refresh only ──────────────────────────────────
  Future<void> _checkLocationStatus({bool showSnackBar = false}) async {
    if (!mounted) return;
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    final enabled = await _location.isLocationServiceEnabled();
    if (!enabled) {
      if (mounted) {
        setState(() {
          _locationError = 'GPS disabled. Please enable location services.';
          _isLoadingLocation = false;
        });
      }
      return;
    }

    final granted = await _location.requestPermission();
    if (!granted) {
      if (mounted) {
        setState(() {
          _locationError = 'Location permission denied.';
          _isLoadingLocation = false;
        });
      }
      return;
    }

    final pos = await _location.getCurrentPosition();
    if (pos == null) {
      if (mounted) {
        setState(() {
          _locationError = 'Unable to get fresh GPS location.';
          _isLoadingLocation = false;
        });
      }
      return;
    }

    if (!mounted) return;
    try {
      final res = await context.read<AttendanceCubit>().preflightGeofence(
            lat: pos.lat,
            lng: pos.lng,
            accuracy: pos.accuracy,
          );
      if (!mounted) return;
      setState(() {
        _geofenceStatus = GeofenceStatus(
          withinRange: res.outcome == PreflightOutcome.inRange,
          distanceMeters: res.distanceMeters ?? 0.0,
          allowedRadiusMeters: res.allowedRadiusMeters ?? 200.0,
          nearestBranch: res.nearestBranch,
        );
        _isLoadingLocation = false;
      });

      if (showSnackBar && mounted) {
        final label = res.nearestBranch ?? 'Office';
        final distanceStr =
            '${(res.distanceMeters ?? 0.0).toStringAsFixed(0)}m';
        final msg = res.outcome == PreflightOutcome.inRange
            ? 'Location updated: Within range of $label ($distanceStr)'
            : 'Location updated: Too far from $label ($distanceStr • allowed ${(res.allowedRadiusMeters ?? 200.0).toStringAsFixed(0)}m)';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: res.outcome == PreflightOutcome.inRange
                ? AppColors.success
                : AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _locationError = 'Geofence check failed.';
          _isLoadingLocation = false;
        });
      }
    }
  }

  // ── Single Clock-In Flow (GPS → Preflight → Biometric → ClockIn) ─────────
  Future<void> _handleClockIn() async {
    final cubit = context.read<AttendanceCubit>();
    if (cubit.state is! AttendanceLoaded) return;
    final state = cubit.state as AttendanceLoaded;

    if (state.todayStatus.clockOutTime != null) return;

    // In-flight guard: cover the ENTIRE user action
    if (state.isCheckingIn) return;

    cubit.setCheckingIn(true);

    try {
      // 1. Obtain a fresh high-accuracy GPS fix
      final enabled = await _location.isLocationServiceEnabled();
      if (!enabled) {
        _showErrorSnackBar('GPS disabled. Please turn on location services.');
        return;
      }

      final granted = await _location.requestPermission();
      if (!granted) {
        _showErrorSnackBar('Location permission denied.');
        return;
      }

      final pos = await _location.getCurrentPosition();
      if (pos == null) {
        _showErrorSnackBar('Unable to obtain a fresh GPS fix. Please retry.');
        return;
      }

      if (pos.accuracy > 50) {
        _showErrorSnackBar(
            'GPS accuracy too low (${pos.accuracy.toStringAsFixed(0)}m). Must be ≤ 50m.');
        return;
      }

      // 2. Server geofence preflight call (GET /attendance/geofence-status)
      final preflight = await cubit.preflightGeofence(
        lat: pos.lat,
        lng: pos.lng,
        accuracy: pos.accuracy,
      );

      if (!mounted) return;

      if (preflight.outcome == PreflightOutcome.inRange ||
          preflight.outcome == PreflightOutcome.outOfRange) {
        setState(() {
          _geofenceStatus = GeofenceStatus(
            withinRange: preflight.outcome == PreflightOutcome.inRange,
            distanceMeters: preflight.distanceMeters ?? 0.0,
            allowedRadiusMeters: preflight.allowedRadiusMeters ?? 200.0,
            nearestBranch: preflight.nearestBranch,
          );
        });
      }

      if (preflight.outcome == PreflightOutcome.serverError) {
        _showErrorSnackBar(
          'Server connection error. If Render backend is sleeping, please try again in a few seconds.',
        );
        return;
      }

      if (preflight.outcome != PreflightOutcome.inRange) {
        final branch = preflight.nearestBranch ?? 'office';
        final dist = preflight.distanceMeters?.toStringAsFixed(0) ?? '?';
        final radius = preflight.allowedRadiusMeters?.toStringAsFixed(0) ?? '200';
        _showErrorSnackBar(
          'You are $dist m away from $branch, outside allowed radius ($radius m).',
        );
        return;
      }

      // 3. Biometric Authentication (Biometric ONLY — no PIN/passcode fallback)
      final biometricAvailable = await _biometric.isBiometricAvailable();
      if (!biometricAvailable) {
        _showErrorSnackBar(
          'Biometric authentication is not available or enabled on this device.',
        );
        return;
      }

      final authenticated = await _biometric
          .authenticateBiometricOnly('Please authenticate biometric to clock in');

      if (!authenticated || !mounted) {
        // Biometric cancelled or failed — DO NOT call clockIn API
        return;
      }

      // 4. Send single clock-in request (POST /attendance/clock-in)
      final record = await cubit.clockIn(
        lat: pos.lat,
        lng: pos.lng,
        accuracy: pos.accuracy,
      );

      // 5. Success confirmation based strictly on persisted server response
      if (record != null && mounted) {
        setState(() => _justClockedIn = true);
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _justClockedIn = false);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Attendance recorded at ${record.locationLabel}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } finally {
      cubit.setCheckingIn(false);
    }
  }

  Future<void> _handleClockOut() async {
    final cubit = context.read<AttendanceCubit>();
    if (cubit.state is! AttendanceLoaded) return;
    final state = cubit.state as AttendanceLoaded;

    if (state.todayStatus.clockOutTime != null) return;

    final biometricAvailable = await _biometric.isBiometricAvailable();
    if (biometricAvailable) {
      final auth = await _biometric.authenticateBiometricOnly(
        'Please authenticate biometric to clock out',
      );
      if (!auth || !mounted) return;
    }
    if (!mounted) return;
    await cubit.clockOut();
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  int _calculateStreak(List<AttendanceRecord> history) {
    int streak = 0;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    final sortedHistory = List<AttendanceRecord>.from(history)
      ..sort((a, b) => b.date.compareTo(a.date));

    DateTime currentCheckDate = todayStart.subtract(const Duration(days: 1));

    for (final record in sortedHistory) {
      final recordDate =
          DateTime(record.date.year, record.date.month, record.date.day);
      if (recordDate.isAfter(todayStart) ||
          recordDate.isAtSameMomentAs(todayStart)) {
        continue;
      }

      if (recordDate.isAtSameMomentAs(currentCheckDate)) {
        if (record.clockInTime != null) {
          streak++;
          currentCheckDate =
              currentCheckDate.subtract(const Duration(days: 1));
        } else {
          break;
        }
      } else if (recordDate.isBefore(currentCheckDate)) {
        break;
      }
    }
    return streak;
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '${'good_morning'.tr()} ☀️';
    if (hour < 17) return '${'good_afternoon'.tr()} 🌤️';
    return '${'good_evening'.tr()} 🌙';
  }

  Color _getGradientStartColor(AttendanceLoaded state) {
    if (state.isWfh) return Colors.indigo.shade400;
    if (state.isOnBreak) return Colors.amber.shade600;

    final isClockedIn = state.todayStatus.clockInTime != null &&
        state.todayStatus.clockOutTime == null;
    if (isClockedIn) return AppColors.primary;

    final hour = DateTime.now().hour;
    if (hour < 12) return const Color(0xFFFF8C69);
    if (hour < 17) return AppColors.primary;
    return const Color(0xFF1E3A5F);
  }

  Color _getGradientEndColor(AttendanceLoaded state) {
    if (state.isWfh) return Colors.indigo.shade800;
    if (state.isOnBreak) return Colors.orange.shade800;

    final isClockedIn = state.todayStatus.clockInTime != null &&
        state.todayStatus.clockOutTime == null;
    if (isClockedIn) return const Color(0xFF074740);

    final hour = DateTime.now().hour;
    if (hour < 12) return const Color(0xFFFF6B4A);
    if (hour < 17) return const Color(0xFF0B6E64);
    return const Color(0xFF0F1C2E);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AttendanceCubit, AttendanceState>(
      listenWhen: (prev, current) {
        if (current is AttendanceError &&
            current.message == 'clock_out_failed') {
          return true;
        }
        return false;
      },
      listener: (context, state) {
        if (state is AttendanceError && state.message == 'clock_out_failed') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('clock_out_error_msg'.tr()),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 10),
              action: SnackBarAction(
                label: 'retry'.tr(),
                textColor: Colors.white,
                onPressed: () =>
                    context.read<AttendanceCubit>().retryClockOut(),
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is AttendanceError) {
          return Container(
            height: 220,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off, color: Colors.orangeAccent, size: 40),
                const SizedBox(height: 10),
                const Text(
                  'Failed to load attendance status',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () =>
                      context.read<AttendanceCubit>().loadAttendanceData(),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        if (state is! AttendanceLoaded) return const AppLoader();

        final todayRec = state.todayStatus;
        final isClockedIn =
            todayRec.clockInTime != null && todayRec.clockOutTime == null;
        final isDayCompleted = todayRec.clockOutTime != null;
        final isActionable = !state.isCheckingIn && !isDayCompleted;

        int streak = _calculateStreak(state.history);
        if (todayRec.clockInTime != null) streak++;

        return AppCard(
          padding: EdgeInsets.zero,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _getGradientStartColor(state),
                  _getGradientEndColor(state),
                ],
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getGreeting(),
                              style: TextStyle(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            const LiveClock(),
                          ],
                        ),
                      ),
                      if (streak > 0)
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 12.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('🔥', style: TextStyle(fontSize: 14.sp)),
                              SizedBox(width: 4.w),
                              Text(
                                '$streak ${'days'.tr()}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 32.h),
                  if (isDayCompleted)
                    Container(
                      key: const Key('completed_day_badge'),
                      padding: EdgeInsets.symmetric(
                          horizontal: 24.w, vertical: 18.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              color: Colors.greenAccent, size: 24),
                          SizedBox(width: 8.w),
                          Flexible(
                            child: Text(
                              'Attendance completed for today',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    AnimatedClockButton(
                      isClockedIn: isClockedIn,
                      isActionable: isActionable,
                      justClockedIn: _justClockedIn,
                      clockInTime: todayRec.clockInTime,
                      onTap: () =>
                          isClockedIn ? _handleClockOut() : _handleClockIn(),
                    ),
                  SizedBox(height: 32.h),
                  LocationStatusIndicator(
                    isLoadingLocation: _isLoadingLocation,
                    locationError: _locationError,
                    geofenceStatus: _geofenceStatus,
                    onRefresh: () =>
                        _checkLocationStatus(showSnackBar: true),
                  ),
                  if (todayRec.clockInTime != null)
                    TodayAttendanceSummary(todayRec: todayRec),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
