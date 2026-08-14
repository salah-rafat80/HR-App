class HrMonthlySummary {
  final String month;
  final int totalEmployees;
  final int totalWorkDays;
  final int totalPresent;
  final int totalAbsent;
  final int totalLate;
  final double totalOvertimeHours;
  final double totalOvertimeCost;

  const HrMonthlySummary({
    required this.month,
    required this.totalEmployees,
    required this.totalWorkDays,
    required this.totalPresent,
    required this.totalAbsent,
    required this.totalLate,
    required this.totalOvertimeHours,
    required this.totalOvertimeCost,
  });

  factory HrMonthlySummary.fromJson(Map<String, dynamic> json) {
    return HrMonthlySummary(
      month: json['month']?.toString() ?? '',
      totalEmployees: (json['totalEmployees'] as num?)?.toInt() ?? 0,
      totalWorkDays: (json['totalWorkDays'] as num?)?.toInt() ?? 0,
      totalPresent: (json['totalPresent'] as num?)?.toInt() ?? 0,
      totalAbsent: (json['totalAbsent'] as num?)?.toInt() ?? 0,
      totalLate: (json['totalLate'] as num?)?.toInt() ?? 0,
      totalOvertimeHours: (json['totalOvertimeHours'] as num?)?.toDouble() ?? 0.0,
      totalOvertimeCost: (json['totalOvertimeCost'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class HrEmployeeSummary {
  final String employeeId;
  final String employeeCode;
  final String name;
  final String department;
  final int presentDays;
  final int absentDays;
  final double overtimeHours;
  final double overtimePay;

  const HrEmployeeSummary({
    required this.employeeId,
    required this.employeeCode,
    required this.name,
    required this.department,
    required this.presentDays,
    required this.absentDays,
    required this.overtimeHours,
    required this.overtimePay,
  });

  factory HrEmployeeSummary.fromJson(Map<String, dynamic> json) {
    return HrEmployeeSummary(
      employeeId: json['employeeId']?.toString() ?? json['id']?.toString() ?? '',
      employeeCode: json['employeeCode']?.toString() ?? json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      department: json['department']?.toString() ?? 'General',
      presentDays: (json['presentDays'] as num?)?.toInt() ?? 0,
      absentDays: (json['absentDays'] as num?)?.toInt() ?? 0,
      overtimeHours: (json['overtimeHours'] as num?)?.toDouble() ?? 0.0,
      overtimePay: (json['overtimePay'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class HrMonthlyReportData {
  final HrMonthlySummary summary;
  final List<HrEmployeeSummary> employees;

  const HrMonthlyReportData({
    required this.summary,
    required this.employees,
  });

  factory HrMonthlyReportData.fromJson(Map<String, dynamic> json) {
    final summaryJson = json['summary'] is Map<String, dynamic>
        ? json['summary'] as Map<String, dynamic>
        : <String, dynamic>{};
    final employeesList = json['employees'] is List
        ? (json['employees'] as List)
            .whereType<Map<String, dynamic>>()
            .map((e) => HrEmployeeSummary.fromJson(e))
            .toList()
        : <HrEmployeeSummary>[];

    return HrMonthlyReportData(
      summary: HrMonthlySummary.fromJson(summaryJson),
      employees: employeesList,
    );
  }
}
