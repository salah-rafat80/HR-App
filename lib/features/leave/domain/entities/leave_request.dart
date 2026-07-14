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
}
