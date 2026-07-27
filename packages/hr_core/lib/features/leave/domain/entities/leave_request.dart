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
        (e) => e.name.toLowerCase() == json['status']?.toString().toLowerCase(),
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
  final String? employeeCode;
  final String? employeeDepartment;
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
    this.employeeCode,
    this.employeeDepartment,
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

  String get displayStatus {
    if (overallStatus != LeaveStatus.pending) {
      return overallStatus.name;
    }
    final pendingStepIndex = approvalSteps.indexWhere((s) => s.status == LeaveStatus.pending);
    if (pendingStepIndex != -1) {
      final step = approvalSteps[pendingStepIndex];
      // stepName is like 'manager', 'hr', 'final_approval'
      final name = step.stepName.replaceAll('_', ' ');
      return 'pending $name';
    }
    return overallStatus.name;
  }

  LeaveRequest copyWith({
    LeaveStatus? overallStatus,
    List<LeaveApprovalStep>? approvalSteps,
  }) {
    return LeaveRequest(
      id: id,
      employeeId: employeeId,
      employeeName: employeeName,
      employeeCode: employeeCode,
      employeeDepartment: employeeDepartment,
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
      employeeCode: json['user']?['code'] as String?,
      employeeDepartment: json['user']?['department'] as String?,
      type: LeaveType.values.firstWhere(
        (e) => e.name.toLowerCase() == json['type']?.toString().toLowerCase(),
        orElse: () => LeaveType.annual,
      ),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      isHalfDay: json['isHalfDay'] as bool? ?? false,
      halfDayPeriod: json['halfDayPeriod'] as String?,
      reason: json['reason'] as String? ?? '',
      hasAttachment: json['hasAttachment'] as bool? ?? false,
      overallStatus: LeaveStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == json['overallStatus']?.toString().toLowerCase(),
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
