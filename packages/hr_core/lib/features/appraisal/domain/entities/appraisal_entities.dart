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
}

class DevelopmentGoal {
  final String title;
  final double progressPercent;

  const DevelopmentGoal({
    required this.title,
    required this.progressPercent,
  });
}

enum CareerStepStatus { completed, current, upcoming }

class CareerStep {
  final String roleTitle;
  final CareerStepStatus status;

  const CareerStep({
    required this.roleTitle,
    required this.status,
  });
}
