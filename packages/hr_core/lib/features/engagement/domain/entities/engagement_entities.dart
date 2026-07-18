import 'package:equatable/equatable.dart';

class PulseSurveyPrompt extends Equatable {
  final String id;
  final String weekLabel;
  final String questionText;
  final int? answer;

  const PulseSurveyPrompt({
    required this.id,
    required this.weekLabel,
    required this.questionText,
    this.answer,
  });

  PulseSurveyPrompt copyWith({int? answer}) {
    return PulseSurveyPrompt(
      id: id,
      weekLabel: weekLabel,
      questionText: questionText,
      answer: answer ?? this.answer,
    );
  }

  @override
  List<Object?> get props => [id, weekLabel, questionText, answer];
}

class EnpsPrompt extends Equatable {
  final String id;
  final String questionText;
  final int? answer;

  const EnpsPrompt({
    required this.id,
    required this.questionText,
    this.answer,
  });

  EnpsPrompt copyWith({int? answer}) {
    return EnpsPrompt(
      id: id,
      questionText: questionText,
      answer: answer ?? this.answer,
    );
  }

  @override
  List<Object?> get props => [id, questionText, answer];
}

class RecognitionBadge extends Equatable {
  final String id;
  final String fromName;
  final String toName;
  final String badgeType;
  final String message;
  final int pointsAwarded;

  const RecognitionBadge({
    required this.id,
    required this.fromName,
    required this.toName,
    required this.badgeType,
    required this.message,
    required this.pointsAwarded,
  });

  @override
  List<Object?> get props => [id, fromName, toName, badgeType, message, pointsAwarded];
}

class RewardItem extends Equatable {
  final String id;
  final String name;
  final int pointsCost;

  const RewardItem({
    required this.id,
    required this.name,
    required this.pointsCost,
  });

  @override
  List<Object?> get props => [id, name, pointsCost];
}
