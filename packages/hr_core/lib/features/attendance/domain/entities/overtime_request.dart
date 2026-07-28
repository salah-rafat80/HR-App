/// Mirrors the backend OvertimeStatus enum exactly.
/// Using a Dart enum (not String) prevents case-mismatch bugs ("Pending" vs "pending").
enum OvertimeStatus { pending, approved, rejected }

class OvertimeRequest {
  final String id;
  final double hours;
  final String reason;
  final OvertimeStatus status;
  final DateTime submittedAt;

  const OvertimeRequest({
    required this.id,
    required this.hours,
    required this.reason,
    required this.status,
    required this.submittedAt,
  });

  factory OvertimeRequest.fromJson(Map<String, dynamic> json) {
    return OvertimeRequest(
      id: json['id']?.toString() ?? '',
      hours: (json['hoursRequested'] as num?)?.toDouble() ?? 0.0,
      reason: json['reason'] ?? '',
      status: OvertimeStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => OvertimeStatus.pending,
      ),
      submittedAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hoursRequested': hours,
      'reason': reason,
      'status': status.name,
      'createdAt': submittedAt.toIso8601String(),
    };
  }
}
