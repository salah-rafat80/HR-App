import 'package:equatable/equatable.dart';
import '../../domain/entities/appraisal_entities.dart';

sealed class AppraisalState extends Equatable {
  const AppraisalState();
  @override
  List<Object?> get props => [];
}

class AppraisalInitial extends AppraisalState {}

class AppraisalLoading extends AppraisalState {}

class AppraisalLoaded extends AppraisalState {
  final AppraisalCycle cycle;
  final List<SelfAppraisalQuestion> questions;
  final List<PeerFeedback> peers;
  final AppraisalResult myResults;
  final List<DevelopmentGoal> devPlan;
  final List<CareerStep> careerPath;
  final double currentKpiScore;
  final bool isSubmitting;
  final String? submitError;
  final bool submitSuccess;

  const AppraisalLoaded({
    required this.cycle,
    required this.questions,
    required this.peers,
    required this.myResults,
    required this.devPlan,
    required this.careerPath,
    required this.currentKpiScore,
    this.isSubmitting = false,
    this.submitError,
    this.submitSuccess = false,
  });

  AppraisalLoaded copyWith({
    AppraisalCycle? cycle,
    List<SelfAppraisalQuestion>? questions,
    List<PeerFeedback>? peers,
    AppraisalResult? myResults,
    List<DevelopmentGoal>? devPlan,
    List<CareerStep>? careerPath,
    double? currentKpiScore,
    bool? isSubmitting,
    String? submitError,
    bool? submitSuccess,
  }) {
    return AppraisalLoaded(
      cycle: cycle ?? this.cycle,
      questions: questions ?? this.questions,
      peers: peers ?? this.peers,
      myResults: myResults ?? this.myResults,
      devPlan: devPlan ?? this.devPlan,
      careerPath: careerPath ?? this.careerPath,
      currentKpiScore: currentKpiScore ?? this.currentKpiScore,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitError: submitError,
      submitSuccess: submitSuccess ?? this.submitSuccess,
    );
  }

  @override
  List<Object?> get props => [
        cycle,
        questions,
        peers,
        myResults,
        devPlan,
        careerPath,
        currentKpiScore,
        isSubmitting,
        submitError,
        submitSuccess,
      ];
}

class AppraisalError extends AppraisalState {
  final String message;
  const AppraisalError(this.message);
  @override
  List<Object?> get props => [message];
}
