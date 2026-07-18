import 'dart:math';
import '../../domain/entities/leave_balance.dart';
import '../../domain/entities/leave_enums.dart';
import '../../domain/entities/leave_request.dart';
import '../../domain/entities/team_leave_entry.dart';
import '../../../../core/enums/role_enums.dart';

class FakeLeaveDataSource {
  final List<LeaveBalance> _balances = [
    const LeaveBalance(type: LeaveType.annual, daysUsed: 6, daysTotal: 24),
    const LeaveBalance(type: LeaveType.sick, daysUsed: 4, daysTotal: 10),
    const LeaveBalance(type: LeaveType.emergency, daysUsed: 1, daysTotal: 3),
    const LeaveBalance(type: LeaveType.maternityPaternity, daysUsed: 0, daysTotal: 90),
    const LeaveBalance(type: LeaveType.unpaid, daysUsed: 0, daysTotal: 30),
    const LeaveBalance(type: LeaveType.study, daysUsed: 0, daysTotal: 14),
    const LeaveBalance(type: LeaveType.hajj, daysUsed: 0, daysTotal: 21),
    const LeaveBalance(type: LeaveType.bereavement, daysUsed: 0, daysTotal: 5),
  ];

  final List<LeaveRequest> _requests = [
    LeaveRequest(
      id: 'req_1',
      type: LeaveType.annual,
      startDate: DateTime.now().subtract(const Duration(days: 1)),
      endDate: DateTime.now().add(const Duration(days: 2)),
      isHalfDay: false,
      reason: 'Family Vacation',
      hasAttachment: false,
      overallStatus: LeaveStatus.approved,
      approvalSteps: [
        LeaveApprovalStep(stepName: 'submitted', status: LeaveStatus.approved, timestamp: DateTime.now().subtract(const Duration(days: 10))),
        LeaveApprovalStep(stepName: 'manager', status: LeaveStatus.approved, timestamp: DateTime.now().subtract(const Duration(days: 9))),
        LeaveApprovalStep(stepName: 'hr', status: LeaveStatus.approved, timestamp: DateTime.now().subtract(const Duration(days: 8))),
        LeaveApprovalStep(stepName: 'final_approval', status: LeaveStatus.approved, timestamp: DateTime.now().subtract(const Duration(days: 7))),
      ],
    ),
    LeaveRequest(
      id: 'req_2',
      type: LeaveType.sick,
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      endDate: DateTime.now().subtract(const Duration(days: 28)),
      isHalfDay: false,
      reason: 'Flu',
      hasAttachment: true,
      overallStatus: LeaveStatus.approved,
      approvalSteps: [
        LeaveApprovalStep(stepName: 'submitted', status: LeaveStatus.approved, timestamp: DateTime.now().subtract(const Duration(days: 32))),
        LeaveApprovalStep(stepName: 'manager', status: LeaveStatus.approved, timestamp: DateTime.now().subtract(const Duration(days: 31))),
        LeaveApprovalStep(stepName: 'hr', status: LeaveStatus.approved, timestamp: DateTime.now().subtract(const Duration(days: 30))),
        LeaveApprovalStep(stepName: 'final_approval', status: LeaveStatus.approved, timestamp: DateTime.now().subtract(const Duration(days: 30))),
      ],
    ),
    LeaveRequest(
      id: 'req_3',
      type: LeaveType.emergency,
      startDate: DateTime.now().add(const Duration(days: 10)),
      endDate: DateTime.now().add(const Duration(days: 10)),
      isHalfDay: true,
      halfDayPeriod: 'morning',
      reason: 'Personal Errands',
      hasAttachment: false,
      overallStatus: LeaveStatus.pending,
      approvalSteps: [
        LeaveApprovalStep(stepName: 'submitted', status: LeaveStatus.approved, timestamp: DateTime.now()),
        LeaveApprovalStep(stepName: 'manager', status: LeaveStatus.pending, timestamp: DateTime.now()),
        LeaveApprovalStep(stepName: 'hr', status: LeaveStatus.pending, timestamp: DateTime.now()),
        LeaveApprovalStep(stepName: 'final_approval', status: LeaveStatus.pending, timestamp: DateTime.now()),
      ],
    ),
    // Other employees' requests for manager/team lead to approve
    LeaveRequest(
      id: 'req_4',
      employeeId: 'emp_1',
      employeeName: 'Ahmed Salem',
      type: LeaveType.annual,
      startDate: DateTime.now().add(const Duration(days: 5)),
      endDate: DateTime.now().add(const Duration(days: 6)),
      isHalfDay: false,
      reason: 'Vacation',
      hasAttachment: false,
      overallStatus: LeaveStatus.pending,
      approvalSteps: [
        LeaveApprovalStep(stepName: 'submitted', status: LeaveStatus.approved, timestamp: DateTime.now()),
        LeaveApprovalStep(stepName: 'manager', status: LeaveStatus.pending, timestamp: DateTime.now()),
        LeaveApprovalStep(stepName: 'hr', status: LeaveStatus.pending, timestamp: DateTime.now()),
        LeaveApprovalStep(stepName: 'final_approval', status: LeaveStatus.pending, timestamp: DateTime.now()),
      ],
    ),
    LeaveRequest(
      id: 'req_5',
      employeeId: 'emp_2',
      employeeName: 'Mona Zaki',
      type: LeaveType.sick,
      startDate: DateTime.now().add(const Duration(days: 2)),
      endDate: DateTime.now().add(const Duration(days: 3)),
      isHalfDay: false,
      reason: 'Doctor Appointment',
      hasAttachment: true,
      overallStatus: LeaveStatus.pending,
      approvalSteps: [
        LeaveApprovalStep(stepName: 'submitted', status: LeaveStatus.approved, timestamp: DateTime.now()),
        LeaveApprovalStep(stepName: 'manager', status: LeaveStatus.pending, timestamp: DateTime.now()),
        LeaveApprovalStep(stepName: 'hr', status: LeaveStatus.pending, timestamp: DateTime.now()),
        LeaveApprovalStep(stepName: 'final_approval', status: LeaveStatus.pending, timestamp: DateTime.now()),
      ],
    ),
  ];

  final List<TeamLeaveEntry> _teamCalendar = [
    TeamLeaveEntry(colleagueName: 'Ahmed Salem', startDate: DateTime.now().add(const Duration(days: 1)), endDate: DateTime.now().add(const Duration(days: 3))),
    TeamLeaveEntry(colleagueName: 'Mona Zaki', startDate: DateTime.now().subtract(const Duration(days: 2)), endDate: DateTime.now().add(const Duration(days: 2))),
  ];

  Future<List<LeaveBalance>> getBalances() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _balances;
  }

  Future<List<LeaveRequest>> getMyRequests() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return _requests.where((r) => r.employeeId == null).toList().reversed.toList();
  }

  Future<void> applyLeave(LeaveRequest draft) async {
    await Future.delayed(const Duration(milliseconds: 1200));
    _requests.add(draft);
    // Deduct balance optimistically
    final index = _balances.indexWhere((b) => b.type == draft.type);
    if (index != -1) {
      final old = _balances[index];
      final days = draft.endDate.difference(draft.startDate).inDays + 1;
      _balances[index] = LeaveBalance(type: old.type, daysUsed: old.daysUsed + days, daysTotal: old.daysTotal);
    }
  }

  Future<void> cancelRequest(String id) async {
    await Future.delayed(const Duration(milliseconds: 600));
    _requests.removeWhere((r) => r.id == id);
  }

  Future<List<TeamLeaveEntry>> getTeamCalendar() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _teamCalendar;
  }

  Future<void> requestEncashment(LeaveType type, int days) async {
    await Future.delayed(const Duration(milliseconds: 800));
  }

  Future<void> advanceApprovalStep(String requestId) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index == -1) return;

    final req = _requests[index];
    if (req.overallStatus != LeaveStatus.pending) return;

    final steps = List<LeaveApprovalStep>.from(req.approvalSteps);
    final pendingStepIndex = steps.indexWhere((s) => s.status == LeaveStatus.pending);
    
    if (pendingStepIndex != -1) {
      // 15% rejection chance at manager step
      final isManagerStep = steps[pendingStepIndex].stepName == 'manager';
      final isRejected = isManagerStep && Random().nextDouble() < 0.15;

      steps[pendingStepIndex] = steps[pendingStepIndex].copyWith(
        status: isRejected ? LeaveStatus.rejected : LeaveStatus.approved,
        timestamp: DateTime.now(),
      );

      LeaveStatus newOverall = LeaveStatus.pending;
      if (isRejected) {
        newOverall = LeaveStatus.rejected;
      } else if (pendingStepIndex == steps.length - 1) {
        newOverall = LeaveStatus.approved;
      }

      _requests[index] = req.copyWith(
        overallStatus: newOverall,
        approvalSteps: steps,
      );
    }
  }

  Future<List<LeaveRequest>> getPendingApprovals(ApprovalScope scope) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // For demo, just return all requests that belong to others and are pending
    return _requests.where((r) => r.employeeId != null && r.overallStatus == LeaveStatus.pending).toList();
  }

  Future<void> approveRequest(String requestId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index == -1) return;
    
    final req = _requests[index];
    final steps = List<LeaveApprovalStep>.from(req.approvalSteps);
    final pendingStepIndex = steps.indexWhere((s) => s.status == LeaveStatus.pending);
    
    if (pendingStepIndex != -1) {
      steps[pendingStepIndex] = steps[pendingStepIndex].copyWith(
        status: LeaveStatus.approved,
        timestamp: DateTime.now(),
      );

      final newOverall = (pendingStepIndex == steps.length - 1) ? LeaveStatus.approved : LeaveStatus.pending;

      _requests[index] = req.copyWith(
        overallStatus: newOverall,
        approvalSteps: steps,
      );
    }
  }

  Future<void> rejectRequest(String requestId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index == -1) return;
    
    final req = _requests[index];
    final steps = List<LeaveApprovalStep>.from(req.approvalSteps);
    final pendingStepIndex = steps.indexWhere((s) => s.status == LeaveStatus.pending);
    
    if (pendingStepIndex != -1) {
      steps[pendingStepIndex] = steps[pendingStepIndex].copyWith(
        status: LeaveStatus.rejected,
        timestamp: DateTime.now(),
      );

      _requests[index] = req.copyWith(
        overallStatus: LeaveStatus.rejected,
        approvalSteps: steps,
      );
    }
  }
}
