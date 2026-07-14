enum TrainingCategory { technical, softSkills, compliance, leadership }

class TrainingCourse {
  final String id;
  final String title;
  final TrainingCategory category;
  final int durationHours;
  final bool isMandatory;
  final bool isEnrolled;
  final double progressPercent;

  const TrainingCourse({
    required this.id,
    required this.title,
    required this.category,
    required this.durationHours,
    this.isMandatory = false,
    this.isEnrolled = false,
    this.progressPercent = 0.0,
  });

  TrainingCourse copyWith({
    bool? isEnrolled,
    double? progressPercent,
  }) {
    return TrainingCourse(
      id: id,
      title: title,
      category: category,
      durationHours: durationHours,
      isMandatory: isMandatory,
      isEnrolled: isEnrolled ?? this.isEnrolled,
      progressPercent: progressPercent ?? this.progressPercent,
    );
  }
}

class Certification {
  final String title;
  final DateTime dateEarned;

  const Certification({
    required this.title,
    required this.dateEarned,
  });
}
