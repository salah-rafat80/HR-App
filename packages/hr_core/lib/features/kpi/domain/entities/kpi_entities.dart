class Kpi {
  final String id;
  final String title;
  final String description;
  final String departmentObjective;
  final double targetValue;
  final double currentValue;
  final String? selfAssessmentText;
  final bool hasEvidence;

  const Kpi({
    required this.id,
    required this.title,
    required this.description,
    required this.departmentObjective,
    required this.targetValue,
    required this.currentValue,
    this.selfAssessmentText,
    this.hasEvidence = false,
  });

  double get progressPercent => targetValue > 0 ? (currentValue / targetValue) : 0.0;

  Kpi copyWith({
    String? selfAssessmentText,
    bool? hasEvidence,
    double? currentValue,
  }) {
    return Kpi(
      id: id,
      title: title,
      description: description,
      departmentObjective: departmentObjective,
      targetValue: targetValue,
      currentValue: currentValue ?? this.currentValue,
      selfAssessmentText: selfAssessmentText ?? this.selfAssessmentText,
      hasEvidence: hasEvidence ?? this.hasEvidence,
    );
  }

  factory Kpi.fromJson(Map<String, dynamic> json) {
    return Kpi(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      departmentObjective: json['departmentObjective'] as String,
      targetValue: (json['targetValue'] as num).toDouble(),
      currentValue: (json['currentValue'] as num).toDouble(),
      selfAssessmentText: json['selfAssessmentText'] as String?,
      hasEvidence: json['hasEvidence'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'departmentObjective': departmentObjective,
      'targetValue': targetValue,
      'currentValue': currentValue,
      'selfAssessmentText': selfAssessmentText,
      'hasEvidence': hasEvidence,
    };
  }
}

class KpiQuarterScore {
  final String quarterLabel;
  final double averageScorePercent;

  const KpiQuarterScore({
    required this.quarterLabel,
    required this.averageScorePercent,
  });

  factory KpiQuarterScore.fromJson(Map<String, dynamic> json) {
    return KpiQuarterScore(
      quarterLabel: json['quarterLabel'] as String,
      averageScorePercent: (json['averageScorePercent'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quarterLabel': quarterLabel,
      'averageScorePercent': averageScorePercent,
    };
  }
}
