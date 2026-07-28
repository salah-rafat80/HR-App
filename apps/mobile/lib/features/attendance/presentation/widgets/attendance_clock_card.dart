import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:local_auth/local_auth.dart';
import 'package:hr_core/features/attendance/domain/entities/attendance_enums.dart';
import 'package:hr_core/features/attendance/domain/entities/attendance_record.dart';
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
  const AttendanceClockCard({super.key});

  @override
  State<AttendanceClockCard> createState() => _AttendanceClockCardState();
}

class _AttendanceClockCardState extends State<AttendanceClockCard> {
  bool _isLoadingLocation = false;
  GeofenceStatus? _geofenceStatus;
  String? _locationError;

  final LocalAuthentication _auth = LocalAuthentication();
  bool _justClockedIn = false; // Flag to trigger success animation

  @override
  void initState() {
    super.initState();
    _checkLocationStatus();
  }

  // ── Location ────────────────────────────────────────────────────────────────
  Future<void> _checkLocationStatus({bool forceRefresh = false, bool showSnackBar = false}) async {
    if (!mounted) return;
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        setState(() {
          _locationError = 'GPS disabled.';
          _isLoadingLocation = false;
        });
      }
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() {
          _locationError = 'Permission denied.';
          _isLoadingLocation = false;
        });
      }
      return;
    }

    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 10)),
      );
    } catch (_) {
      position = await Geolocator.getLastKnownPosition();
    }

    if (position == null) {
      if (mounted) {
        setState(() {
          _locationError = 'No GPS signal.';
          _isLoadingLocation = false;
        });
      }
      return;
    }

    if (!mounted) return;
    try {
      final status = await context.read<AttendanceCubit>().checkGeofence(
            position.latitude,
            position.longitude,
            forceRefresh: forceRefresh,
          );
      if (!mounted) return;
      setState(() {
        _geofenceStatus = status;
        _isLoadingLocation = false;
      });

      if (showSnackBar && mounted) {
        final label = status.locationLabel ?? 'Office';
        final distanceStr = '${status.distanceMeters.toStringAsFixed(0)}m';
        final msg = status.withinRange
            ? 'Location updated: Within range of $label ($distanceStr)'
            : 'Location updated: Too far from $label ($distanceStr • allowed ${status.allowedRadiusMeters.toStringAsFixed(0)}m)';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: status.withinRange ? AppColors.success : AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationError = 'Geofence error.';
          _isLoadingLocation = false;
        });
      }
    }
  }

  // ── Biometric ───────────────────────────────────────────────────────────────
  Future<bool> _authenticateUser(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(biometricOnly: false, stickyAuth: true),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Authentication error: $e')));
      }
      return false;
    }
  }

  // ── Actions ─────────────────────────────────────────────────────────────────
  Future<void> _handleClockIn() async {
    if (_geofenceStatus == null || !_geofenceStatus!.withinRange) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You are not in range of the office (${_geofenceStatus?.distanceMeters.toStringAsFixed(0) ?? '?'}m away)')),
      );
      return;
    }

    final authenticated = await _authenticateUser('Please authenticate to clock in');
    if (!authenticated || !mounted) return;

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 5)),
      );
      if (!mounted) return;
      context.read<AttendanceCubit>().clockIn(
            locationLabel: _geofenceStatus?.locationLabel ?? 'Office',
            lat: position.latitude,
            lng: position.longitude,
            accuracy: position.accuracy,
          );
    } catch (e) {
      if (!mounted) return;
      context.read<AttendanceCubit>().clockIn(
            locationLabel: _geofenceStatus?.locationLabel ?? 'Office',
          );
    }
  }

  Future<void> _handleClockOut() async {
    final authenticated = await _authenticateUser('Please authenticate to clock out');
    if (!authenticated || !mounted) return;
    context.read<AttendanceCubit>().clockOut();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────
  int _calculateStreak(List<AttendanceRecord> history) {
    int streak = 0;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    
    final sortedHistory = List<AttendanceRecord>.from(history)
      ..sort((a, b) => b.date.compareTo(a.date));

    DateTime currentCheckDate = todayStart.subtract(const Duration(days: 1));
    
    for (final record in sortedHistory) {
      final recordDate = DateTime(record.date.year, record.date.month, record.date.day);
      if (recordDate.isAfter(todayStart) || recordDate.isAtSameMomentAs(todayStart)) continue;
      
      if (recordDate.isAtSameMomentAs(currentCheckDate)) {
        if (record.clockInTime != null) {
          streak++;
          currentCheckDate = currentCheckDate.subtract(const Duration(days: 1));
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
    
    final isClockedIn = state.todayStatus.clockInTime != null && state.todayStatus.clockOutTime == null;
    if (isClockedIn) return AppColors.primary;

    final hour = DateTime.now().hour;
    if (hour < 12) return const Color(0xFFFF8C69); // Warm coral
    if (hour < 17) return AppColors.primary; // Teal
    return const Color(0xFF1E3A5F); // Deep indigo
  }

  Color _getGradientEndColor(AttendanceLoaded state) {
    if (state.isWfh) return Colors.indigo.shade800;
    if (state.isOnBreak) return Colors.orange.shade800;
    
    final isClockedIn = state.todayStatus.clockInTime != null && state.todayStatus.clockOutTime == null;
    if (isClockedIn) return const Color(0xFF074740);

    final hour = DateTime.now().hour;
    if (hour < 12) return const Color(0xFFFF6B4A);
    if (hour < 17) return const Color(0xFF0B6E64);
    return const Color(0xFF0F1C2E);
  }

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AttendanceCubit, AttendanceState>(
      listenWhen: (prev, current) {
        if (current is AttendanceError && current.message == 'clock_out_failed') return true;
        if (prev is AttendanceLoaded && current is AttendanceLoaded) {
          // Detect clock in success
          if (prev.todayStatus.clockInTime == null && current.todayStatus.clockInTime != null) return true;
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
                onPressed: () => context.read<AttendanceCubit>().retryClockOut(),
              ),
            ),
          );
        } else if (state is AttendanceLoaded) {
          // Trigger celebratory burst
          if (mounted) {
            setState(() => _justClockedIn = true);
            Future.delayed(const Duration(seconds: 3), () {
              if (mounted) setState(() => _justClockedIn = false);
            });
          }
        }
      },
      builder: (context, state) {
        if (state is! AttendanceLoaded) return const AppLoader();

        final todayRec = state.todayStatus;
        final isClockedIn = todayRec.clockInTime != null && todayRec.clockOutTime == null;
        final isActionable = _geofenceStatus?.withinRange == true && !isClockedIn;
        
        int streak = _calculateStreak(state.history);
        if (todayRec.clockInTime != null) streak++; // Add today

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
                  // ── Header: Greeting & Streak ──────────────────────────────
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
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
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

                  // ── Central Clock Button ────────────────────────────────────
                  AnimatedClockButton(
                    isClockedIn: isClockedIn,
                    isActionable: isActionable,
                    justClockedIn: _justClockedIn,
                    clockInTime: todayRec.clockInTime,
                    onTap: () => isClockedIn ? _handleClockOut() : _handleClockIn(),
                  ),
                  SizedBox(height: 32.h),

                  // ── Location Indicator ──────────────────────────────────────
                  LocationStatusIndicator(
                    isLoadingLocation: _isLoadingLocation,
                    locationError: _locationError,
                    geofenceStatus: _geofenceStatus,
                    onRefresh: () => _checkLocationStatus(forceRefresh: true, showSnackBar: true),
                  ),
                  
                  // ── Today Summary ───────────────────────────────────────────
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

