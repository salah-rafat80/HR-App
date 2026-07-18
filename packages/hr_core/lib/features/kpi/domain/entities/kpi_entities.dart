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
}

class KpiQuarterScore {
  final String quarterLabel;
  final double averageScorePercent;

  const KpiQuarterScore({
    required this.quarterLabel,
    required this.averageScorePercent,
  });
}
