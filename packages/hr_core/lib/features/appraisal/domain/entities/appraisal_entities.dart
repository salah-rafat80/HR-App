enum AppraisalStatus { upcoming, inProgress, completed }

class AppraisalCycle {
  final String cycleLabel;
  final AppraisalStatus status;
  final DateTime dueDate;
  final bool selfAppraisalSubmitted;

  const AppraisalCycle({
    required this.cycleLabel,
    required this.status,
    required this.dueDate,
    this.selfAppraisalSubmitted = false,
  });

  AppraisalCycle copyWith({bool? selfAppraisalSubmitted}) {
    return AppraisalCycle(
      cycleLabel: cycleLabel,
      status: status,
      dueDate: dueDate,
      selfAppraisalSubmitted: selfAppraisalSubmitted ?? this.selfAppraisalSubmitted,
    );
  }

  factory AppraisalCycle.fromJson(Map<String, dynamic> json) {
    return AppraisalCycle(
      cycleLabel: json['cycleLabel'] as String,
      status: AppraisalStatus.values.byName(json['status'] as String),
      dueDate: DateTime.parse(json['dueDate'] as String),
      selfAppraisalSubmitted: json['selfAppraisalSubmitted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cycleLabel': cycleLabel,
      'status': status.name,
      'dueDate': dueDate.toIso8601String(),
      'selfAppraisalSubmitted': selfAppraisalSubmitted,
    };
  }
}

class SelfAppraisalQuestion {
  final String id;
  final String questionText;
  final String? answerText;

  const SelfAppraisalQuestion({
    required this.id,
    required this.questionText,
    this.answerText,
  });

  SelfAppraisalQuestion copyWith({String? answerText}) {
    return SelfAppraisalQuestion(
      id: id,
      questionText: questionText,
      answerText: answerText ?? this.answerText,
    );
  }

  factory SelfAppraisalQuestion.fromJson(Map<String, dynamic> json) {
    return SelfAppraisalQuestion(
      id: json['id'] as String,
      questionText: json['questionText'] as String,
      answerText: json['answerText'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'questionText': questionText,
      'answerText': answerText,
    };
  }
}

class Colleague {
  final String id;
  final String name;
  final String role;
  final String avatarInitial;

  const Colleague({
    required this.id,
    required this.name,
    required this.role,
    required this.avatarInitial,
  });

  factory Colleague.fromJson(Map<String, dynamic> json) {
    return Colleague(
      id: json['id'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
      avatarInitial: json['avatarInitial'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'avatarInitial': avatarInitial,
    };
  }
}

class PeerFeedback {
  final Colleague colleague;
  final String? feedbackText;
  final bool submitted;

  const PeerFeedback({
    required this.colleague,
    this.feedbackText,
    this.submitted = false,
  });

  PeerFeedback copyWith({String? feedbackText, bool? submitted}) {
    return PeerFeedback(
      colleague: colleague,
      feedbackText: feedbackText ?? this.feedbackText,
      submitted: submitted ?? this.submitted,
    );
  }

  factory PeerFeedback.fromJson(Map<String, dynamic> json) {
    return PeerFeedback(
      colleague: Colleague.fromJson(json['colleague'] as Map<String, dynamic>),
      feedbackText: json['feedbackText'] as String?,
      submitted: json['submitted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'colleague': colleague.toJson(),
      'feedbackText': feedbackText,
      'submitted': submitted,
    };
  }
}

class AppraisalCategoryRating {
  final String categoryName;
  final double score;
  final String managerComment;

  const AppraisalCategoryRating({
    required this.categoryName,
    required this.score,
    required this.managerComment,
  });

  factory AppraisalCategoryRating.fromJson(Map<String, dynamic> json) {
    return AppraisalCategoryRating(
      categoryName: json['categoryName'] as String,
      score: (json['score'] as num).toDouble(),
      managerComment: json['managerComment'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryName': categoryName,
      'score': score,
      'managerComment': managerComment,
    };
  }
}

class AppraisalResult {
  final double overallRating;
  final List<AppraisalCategoryRating> categoryRatings;
  final String managerSummary;

  const AppraisalResult({
    required this.overallRating,
    required this.categoryRatings,
    required this.managerSummary,
  });

  factory AppraisalResult.fromJson(Map<String, dynamic> json) {
    return AppraisalResult(
      overallRating: (json['overallRating'] as num).toDouble(),
      categoryRatings: (json['categoryRatings'] as List)
          .map((e) => AppraisalCategoryRating.fromJson(e as Map<String, dynamic>))
          .toList(),
      managerSummary: json['managerSummary'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'overallRating': overallRating,
      'categoryRatings': categoryRatings.map((e) => e.toJson()).toList(),
      'managerSummary': managerSummary,
    };
  }
}

class DevelopmentGoal {
  final String title;
  final double progressPercent;

  const DevelopmentGoal({
    required this.title,
    required this.progressPercent,
  });

  factory DevelopmentGoal.fromJson(Map<String, dynamic> json) {
    return DevelopmentGoal(
      title: json['title'] as String,
      progressPercent: (json['progressPercent'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'progressPercent': progressPercent,
    };
  }
}

enum CareerStepStatus { completed, current, upcoming }

class CareerStep {
  final String roleTitle;
  final CareerStepStatus status;

  const CareerStep({
    required this.roleTitle,
    required this.status,
  });

  factory CareerStep.fromJson(Map<String, dynamic> json) {
    return CareerStep(
      roleTitle: json['roleTitle'] as String,
      status: CareerStepStatus.values.byName(json['status'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roleTitle': roleTitle,
      'status': status.name,
    };
  }
}
