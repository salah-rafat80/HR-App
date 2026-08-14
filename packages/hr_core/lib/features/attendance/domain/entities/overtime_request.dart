enum OvertimeStatus {
  pending,
  approved,
  rejected,
  pendingTeamLead,
  pendingHr,
  rejectedByTeamLead,
  rejectedByHr,
  cancelled,
  expired,
  completed,
}

enum OvertimeSessionStatus { active, completed, cancelled }

class OvertimeSession {
  final String id;
  final String overtimeRequestId;
  final OvertimeSessionStatus status;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int? actualMinutes;
  final String? startLocationLabel;
  final String? endLocationLabel;

  const OvertimeSession({
    required this.id,
    required this.overtimeRequestId,
    required this.status,
    required this.startedAt,
    this.endedAt,
    this.actualMinutes,
    this.startLocationLabel,
    this.endLocationLabel,
  });

  factory OvertimeSession.fromJson(Map<String, dynamic> json) {
    return OvertimeSession(
      id: json['id']?.toString() ?? '',
      overtimeRequestId: json['overtimeRequestId']?.toString() ?? '',
      status: _sessionStatusFromWire(json['status']?.toString()),
      startedAt: DateTime.tryParse(json['startedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      endedAt: DateTime.tryParse(json['endedAt']?.toString() ?? ''),
      actualMinutes: (json['actualMinutes'] as num?)?.toInt(),
      startLocationLabel: json['startLocationLabel']?.toString(),
      endLocationLabel: json['endLocationLabel']?.toString(),
    );
  }
}

class OvertimeRequest {
  final String id;
  final String userId;
  final String? employeeName;
  final String? employeeCode;
  final String? department;
  final DateTime date;
  final DateTime? requestedStartAt;
  final DateTime? requestedEndAt;
  final int? requestedMinutes;
  final String reason;
  final OvertimeStatus status;
  final DateTime submittedAt;
  final String? teamLeadComment;
  final String? hrComment;
  final OvertimeSession? session;

  const OvertimeRequest({
    required this.id,
    required this.userId,
    required this.date,
    required this.reason,
    required this.status,
    required this.submittedAt,
    this.employeeName,
    this.employeeCode,
    this.department,
    this.requestedStartAt,
    this.requestedEndAt,
    this.requestedMinutes,
    this.teamLeadComment,
    this.hrComment,
    this.session,
  });

  double get requestedHours =>
      (requestedMinutes ?? 0) / Duration.minutesPerHour;

  bool get isApproved => status == OvertimeStatus.approved;
  bool get hasActiveSession => session?.status == OvertimeSessionStatus.active;

  factory OvertimeRequest.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    final userMap = user is Map<String, dynamic>
        ? user
        : user is Map
            ? Map<String, dynamic>.from(user)
            : const <String, dynamic>{};
    final session = json['session'];
    final sessionMap = session is Map<String, dynamic>
        ? session
        : session is Map
            ? Map<String, dynamic>.from(session)
            : null;

    return OvertimeRequest(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      employeeName: userMap['name']?.toString(),
      employeeCode: userMap['employeeCode']?.toString(),
      department: userMap['department']?.toString(),
      date: DateTime.tryParse(json['date']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      requestedStartAt:
          DateTime.tryParse(json['requestedStartAt']?.toString() ?? ''),
      requestedEndAt:
          DateTime.tryParse(json['requestedEndAt']?.toString() ?? ''),
      requestedMinutes: _requestedMinutesFromJson(json),
      reason: json['reason']?.toString() ?? '',
      status: _requestStatusFromWire(json['status']?.toString()),
      submittedAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      teamLeadComment: json['teamLeadComment']?.toString(),
      hrComment: json['hrComment']?.toString(),
      session: sessionMap == null ? null : OvertimeSession.fromJson(sessionMap),
    );
  }
}

int? _requestedMinutesFromJson(Map<String, dynamic> json) {
  final minutes = (json['requestedMinutes'] as num?)?.toInt();
  if (minutes != null) return minutes;
  final legacyHours = (json['hoursRequested'] as num?)?.toDouble();
  return legacyHours == null
      ? null
      : (legacyHours * Duration.minutesPerHour).round();
}

OvertimeStatus _requestStatusFromWire(String? value) {
  return switch (value) {
    'pending_team_lead' => OvertimeStatus.pendingTeamLead,
    'pending_hr' => OvertimeStatus.pendingHr,
    'rejected_by_team_lead' => OvertimeStatus.rejectedByTeamLead,
    'rejected_by_hr' => OvertimeStatus.rejectedByHr,
    'cancelled' => OvertimeStatus.cancelled,
    'expired' => OvertimeStatus.expired,
    'completed' => OvertimeStatus.completed,
    'approved' => OvertimeStatus.approved,
    'rejected' => OvertimeStatus.rejected,
    _ => OvertimeStatus.pending,
  };
}

OvertimeSessionStatus _sessionStatusFromWire(String? value) {
  return switch (value) {
    'completed' => OvertimeSessionStatus.completed,
    'cancelled' => OvertimeSessionStatus.cancelled,
    _ => OvertimeSessionStatus.active,
  };
}
