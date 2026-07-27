enum AttendanceStatus {
  present,
  absent,
  late,
  workFromHome,
  onBusinessTrip,
  onLeave,
  none,
}

class GeofenceStatus {
  final bool withinRange;
  final double distanceMeters;
  final double allowedRadiusMeters;
  final String? locationLabel;

  const GeofenceStatus({
    required this.withinRange,
    required this.distanceMeters,
    required this.allowedRadiusMeters,
    this.locationLabel,
  });
}
