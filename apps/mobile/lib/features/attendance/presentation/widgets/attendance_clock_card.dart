import 'package:flutter/material.dart';
import 'package:hr_app_demo/core/theme/app_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:local_auth/local_auth.dart';
import 'package:hr_core/features/attendance/domain/entities/attendance_enums.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/attendance_cubit.dart';
import '../bloc/attendance_state.dart';
import 'package:hr_app_demo/core/widgets/app_loader.dart';
import '../../../../core/widgets/app_card.dart';

class AttendanceClockCard extends StatefulWidget {
  const AttendanceClockCard({super.key});

  @override
  State<AttendanceClockCard> createState() => _AttendanceClockCardState();
}

class _AttendanceClockCardState extends State<AttendanceClockCard> {
  bool _isLoadingLocation = false;
  GeofenceStatus? _geofenceStatus;
  String? _locationError;

  final LocalAuthentication auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _checkLocationStatus();
  }

  Future<void> _checkLocationStatus({bool forceRefresh = false, bool showSnackBar = false}) async {
    if (!mounted) return;
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    // ── Step 1: Permissions ──────────────────────────────────────────────────
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        setState(() {
          _locationError = 'GPS is disabled. Please enable location services.';
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
          _locationError = 'Location permission denied.';
          _isLoadingLocation = false;
        });
      }
      return;
    }

    // ── Step 2: Get GPS position (fresh fix) ──────────────────────────
    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (_) {
      position = await Geolocator.getLastKnownPosition();
    }

    if (position == null) {
      if (mounted) {
        setState(() {
          _locationError = 'Could not get GPS signal. Please try again outdoors.';
          _isLoadingLocation = false;
        });
      }
      return;
    }

    // ── Step 3: Ask AttendanceCubit for Geofence Status ──────────────────────
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
        final distanceStr = status.distanceMeters > 99999 ? 'far' : '${status.distanceMeters.toStringAsFixed(0)}m';
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
          _locationError = 'Server error checking geofence. Tap refresh to retry.';
          _isLoadingLocation = false;
        });
      }
    }
  }

  Future<void> _handleClockIn() async {
    if (_geofenceStatus == null || !_geofenceStatus!.withinRange) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You are not in range of the office (${_geofenceStatus?.distanceMeters.toStringAsFixed(0) ?? '?'}m away)')),
      );
      return;
    }

    bool authenticated = false;
    try {
      authenticated = await auth.authenticate(
        localizedReason: 'Please authenticate to clock in',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Authentication error: $e')),
      );
      return;
    }

    if (authenticated && mounted) {
      try {
        Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 5),
          ),
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
        context.read<AttendanceCubit>().clockIn(locationLabel: _geofenceStatus?.locationLabel ?? 'Office');
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AttendanceCubit, AttendanceState>(
      builder: (context, state) {
        if (state is! AttendanceLoaded) return const AppLoader();
        
        final isClockedIn = state.todayStatus.clockInTime != null && state.todayStatus.clockOutTime == null;

        Widget locationIndicator;
        if (_isLoadingLocation) {
          locationIndicator = const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 8),
              Text('Checking location...', style: TextStyle(color: Colors.grey)),
            ],
          );
        } else if (_locationError != null) {
          locationIndicator = Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_off, color: AppColors.error),
              SizedBox(width: 8.w),
              Flexible(child: Text(_locationError!, style: TextStyle(color: AppColors.error))),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: () => _checkLocationStatus(forceRefresh: true, showSnackBar: true),
              )
            ],
          );
        } else if (_geofenceStatus != null) {
          final inRange = _geofenceStatus!.withinRange;
          final branchName = _geofenceStatus!.locationLabel ?? 'Office';
          final distanceStr = _geofenceStatus!.distanceMeters > 99999
              ? 'far'
              : '${_geofenceStatus!.distanceMeters.toStringAsFixed(0)}m';

          locationIndicator = Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                inRange ? AppIcons.modules : Icons.location_off,
                color: inRange ? AppColors.success : AppColors.error,
              ),
              SizedBox(width: 8.w),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      inRange ? '✅ $branchName' : '❌ $branchName',
                      style: TextStyle(
                        color: inRange ? AppColors.success : AppColors.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 15.sp,
                      ),
                    ),
                    Text(
                      inRange
                          ? '($distanceStr • Within range)'
                          : 'Too far ($distanceStr away • max ${_geofenceStatus!.allowedRadiusMeters.toStringAsFixed(0)}m)',
                      style: TextStyle(
                        color: inRange ? AppColors.success : AppColors.error,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: () => _checkLocationStatus(forceRefresh: true, showSnackBar: true),
              ),
            ],
          );
        } else {
          locationIndicator = const SizedBox.shrink();
        }


        final todayRec = state.todayStatus;
        final isArabic = context.locale.languageCode == 'ar';
        final timeFormat = DateFormat('hh:mm a', context.locale.languageCode);

        Widget todaySummaryWidget = const SizedBox.shrink();
        if (todayRec.clockInTime != null) {
          final inStr = timeFormat.format(todayRec.clockInTime!);
          final outStr = todayRec.clockOutTime != null
              ? timeFormat.format(todayRec.clockOutTime!)
              : (isArabic ? 'جاري العمل...' : 'Working...');

          todaySummaryWidget = Container(
            margin: EdgeInsets.only(top: 20.h),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),

            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(isArabic ? 'توقيت الحضور' : 'Check In Time',
                        style: TextStyle(fontSize: 11.sp, color: Colors.grey[600])),
                    SizedBox(height: 4.h),
                    Text(inStr,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.sp,
                            color: AppColors.success)),
                  ],
                ),
                Container(height: 24.h, width: 1, color: Colors.grey[350]),
                Column(
                  children: [
                    Text(isArabic ? 'توقيت الانصراف' : 'Check Out Time',
                        style: TextStyle(fontSize: 11.sp, color: Colors.grey[600])),
                    SizedBox(height: 4.h),
                    Text(outStr,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.sp,
                            color: todayRec.clockOutTime != null
                                ? AppColors.error
                                : Colors.orange)),
                  ],
                ),
              ],
            ),
          );
        }

        return AppCard(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                locationIndicator,
                SizedBox(height: 24.h),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isClockedIn ? AppColors.error : AppColors.primary,
                    shape: const CircleBorder(),
                    padding: EdgeInsets.all(40.w),
                  ),
                  onPressed: () {
                    isClockedIn ? context.read<AttendanceCubit>().clockOut() : _handleClockIn();
                  },
                  child: Text(isClockedIn ? 'clock_out'.tr() : 'clock_in'.tr(), style: TextStyle(fontSize: 18.sp)),
                ),
                todaySummaryWidget,
              ],
            ),
          ),
        );

      },
    );
  }
}
