import 'leave_enums.dart';

class LeaveApprovalStep {
  final String stepName;
  final LeaveStatus status;
  final DateTime timestamp;

  const LeaveApprovalStep({
    required this.stepName,
    required this.status,
    required this.timestamp,
  });

  LeaveApprovalStep copyWith({
    String? stepName,
    LeaveStatus? status,
    DateTime? timestamp,
  }) {
    return LeaveApprovalStep(
      stepName: stepName ?? this.stepName,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  factory LeaveApprovalStep.fromJson(Map<String, dynamic> json) {
    return LeaveApprovalStep(
      stepName: json['stepName'] as String,
      status: LeaveStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => LeaveStatus.pending,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stepName': stepName,
      'status': status.name,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class LeaveRequest {
  final String id;
  final String? employeeId;
  final String? employeeName;
  final LeaveType type;
  final DateTime startDate;
  final DateTime endDate;
  final bool isHalfDay;
  final String? halfDayPeriod;
  final String reason;
  final bool hasAttachment;
  final LeaveStatus overallStatus;
  final List<LeaveApprovalStep> approvalSteps;

  const LeaveRequest({
    required this.id,
    this.employeeId,
    this.employeeName,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.isHalfDay,
    this.halfDayPeriod,
    required this.reason,
    required this.hasAttachment,
    required this.overallStatus,
    required this.approvalSteps,
  });

  LeaveRequest copyWith({
    LeaveStatus? overallStatus,
    List<LeaveApprovalStep>? approvalSteps,
  }) {
    return LeaveRequest(
      id: id,
      employeeId: employeeId,
      employeeName: employeeName,
      type: type,
      startDate: startDate,
      endDate: endDate,
      isHalfDay: isHalfDay,
      halfDayPeriod: halfDayPeriod,
      reason: reason,
      hasAttachment: hasAttachment,
      overallStatus: overallStatus ?? this.overallStatus,
      approvalSteps: approvalSteps ?? this.approvalSteps,
    );
  }

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    return LeaveRequest(
      id: json['id'] as String,
      employeeId: json['userId'] as String?,
      employeeName: json['user']?['name'] as String?,
      type: LeaveType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => LeaveType.annual,
      ),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      isHalfDay: json['isHalfDay'] as bool? ?? false,
      halfDayPeriod: json['halfDayPeriod'] as String?,
      reason: json['reason'] as String? ?? '',
      hasAttachment: json['hasAttachment'] as bool? ?? false,
      overallStatus: LeaveStatus.values.firstWhere(
        (e) => e.name == json['overallStatus'],
        orElse: () => LeaveStatus.pending,
      ),
      approvalSteps: (json['approvalSteps'] as List<dynamic>?)
              ?.map((e) => LeaveApprovalStep.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': employeeId,
      'type': type.name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isHalfDay': isHalfDay,
      'halfDayPeriod': halfDayPeriod,
      'reason': reason,
      'hasAttachment': hasAttachment,
      'overallStatus': overallStatus.name,
      'approvalSteps': approvalSteps.map((e) => e.toJson()).toList(),
    };
  }
}
