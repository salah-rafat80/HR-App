enum AttendanceStatus {
  present,
  absent,
  late,
  workFromHome,
  onBusinessTrip,
  onLeave,
  none,
}

/// Result returned by the backend geofence preflight endpoint.
class GeofenceStatus {
  final bool withinRange;
  final double distanceMeters;
  final double allowedRadiusMeters;

  /// Server-derived branch name — never from client.
  final String? nearestBranch;

  const GeofenceStatus({
    required this.withinRange,
    required this.distanceMeters,
    required this.allowedRadiusMeters,
    this.nearestBranch,
  });
}
