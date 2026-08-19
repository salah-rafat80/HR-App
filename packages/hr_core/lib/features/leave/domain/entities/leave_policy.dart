import 'leave_enums.dart';

class LeavePolicy {
  final String id;
  final LeaveType type;
  final String displayNameAr;
  final double annualEntitlement;
  final bool isPaid;
  final bool requiresBalance;
  final bool allowHalfDay;
  final int minimumNoticeDays;
  final bool requiresReason;
  final bool isActive;

  const LeavePolicy({
    required this.id,
    required this.type,
    required this.displayNameAr,
    required this.annualEntitlement,
    required this.isPaid,
    required this.requiresBalance,
    required this.allowHalfDay,
    required this.minimumNoticeDays,
    required this.requiresReason,
    required this.isActive,
  });

  factory LeavePolicy.fromJson(Map<String, dynamic> json) {
    return LeavePolicy(
      id: json['id'] as String,
      type: LeaveType.values.firstWhere(
        (e) => e.name.toLowerCase() == json['type']?.toString().toLowerCase(),
        orElse: () => LeaveType.annual,
      ),
      displayNameAr: json['displayNameAr'] as String? ?? '',
      annualEntitlement: double.tryParse(json['annualEntitlement']?.toString() ?? '0') ?? 0.0,
      isPaid: json['isPaid'] as bool? ?? true,
      requiresBalance: json['requiresBalance'] as bool? ?? true,
      allowHalfDay: json['allowHalfDay'] as bool? ?? true,
      minimumNoticeDays: json['minimumNoticeDays'] as int? ?? 0,
      requiresReason: json['requiresReason'] as bool? ?? true,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'displayNameAr': displayNameAr,
      'annualEntitlement': annualEntitlement,
      'isPaid': isPaid,
      'requiresBalance': requiresBalance,
      'allowHalfDay': allowHalfDay,
      'minimumNoticeDays': minimumNoticeDays,
      'requiresReason': requiresReason,
      'isActive': isActive,
    };
  }

  LeavePolicy copyWith({
    String? displayNameAr,
    double? annualEntitlement,
    bool? isPaid,
    bool? requiresBalance,
    bool? allowHalfDay,
    int? minimumNoticeDays,
    bool? requiresReason,
    bool? isActive,
  }) {
    return LeavePolicy(
      id: id,
      type: type,
      displayNameAr: displayNameAr ?? this.displayNameAr,
      annualEntitlement: annualEntitlement ?? this.annualEntitlement,
      isPaid: isPaid ?? this.isPaid,
      requiresBalance: requiresBalance ?? this.requiresBalance,
      allowHalfDay: allowHalfDay ?? this.allowHalfDay,
      minimumNoticeDays: minimumNoticeDays ?? this.minimumNoticeDays,
      requiresReason: requiresReason ?? this.requiresReason,
      isActive: isActive ?? this.isActive,
    );
  }
}
