import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hr_core/features/attendance/domain/entities/attendance_enums.dart';

class LocationStatusIndicator extends StatelessWidget {
  final bool isLoadingLocation;
  final String? locationError;
  final GeofenceStatus? geofenceStatus;
  final VoidCallback onRefresh;

  const LocationStatusIndicator({
    super.key,
    required this.isLoadingLocation,
    this.locationError,
    this.geofenceStatus,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoadingLocation) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(width: 14.w, height: 14.w, child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white70)),
          SizedBox(width: 8.w),
          Text('checking_location'.tr(), style: TextStyle(color: Colors.white70, fontSize: 12.sp)),
        ],
      );
    } else if (locationError != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off, color: Colors.red[300], size: 16.sp),
          SizedBox(width: 8.w),
          Flexible(child: Text(locationError!, style: TextStyle(color: Colors.red[300], fontSize: 12.sp))),
          IconButton(
            icon: Icon(Icons.refresh, size: 18.sp, color: Colors.white),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: onRefresh,
          )
        ],
      );
    } else if (geofenceStatus != null) {
      final inRange = geofenceStatus!.withinRange;
      final branchName = geofenceStatus!.locationLabel ?? 'Office';
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            inRange ? Icons.location_on : Icons.location_off,
            color: inRange ? Colors.white : Colors.red[300],
            size: 16.sp,
          ),
          SizedBox(width: 6.w),
          Flexible(
            child: Text(
              inRange ? branchName : 'Too far from $branchName',
              style: TextStyle(
                color: inRange ? Colors.white : Colors.red[300],
                fontSize: 13.sp,
                fontWeight: inRange ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
          SizedBox(width: 6.w),
          IconButton(
            icon: Icon(Icons.refresh, size: 18.sp, color: Colors.white70),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: onRefresh,
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}
