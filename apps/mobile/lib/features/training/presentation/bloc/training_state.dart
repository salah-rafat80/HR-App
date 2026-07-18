import 'package:equatable/equatable.dart';
import 'package:hr_core/features/training/domain/entities/training_entities.dart';

sealed class TrainingState extends Equatable {
  const TrainingState();
  @override
  List<Object?> get props => [];
}

class TrainingInitial extends TrainingState {}

class TrainingLoading extends TrainingState {}

class TrainingLoaded extends TrainingState {
  final List<TrainingCourse> availableCourses;
  final List<TrainingCourse> myEnrollments;
  final List<Certification> certifications;
  final List<TrainingCourse> pendingMandatory;
  final bool isEnrolling;
  final String? enrollError;

  const TrainingLoaded({
    required this.availableCourses,
    required this.myEnrollments,
    required this.certifications,
    required this.pendingMandatory,
    this.isEnrolling = false,
    this.enrollError,
  });

  TrainingLoaded copyWith({
    List<TrainingCourse>? availableCourses,
    List<TrainingCourse>? myEnrollments,
    List<Certification>? certifications,
    List<TrainingCourse>? pendingMandatory,
    bool? isEnrolling,
    String? enrollError,
  }) {
    return TrainingLoaded(
      availableCourses: availableCourses ?? this.availableCourses,
      myEnrollments: myEnrollments ?? this.myEnrollments,
      certifications: certifications ?? this.certifications,
      pendingMandatory: pendingMandatory ?? this.pendingMandatory,
      isEnrolling: isEnrolling ?? this.isEnrolling,
      enrollError: enrollError,
    );
  }

  @override
  List<Object?> get props => [availableCourses, myEnrollments, certifications, pendingMandatory, isEnrolling, enrollError];
}

class TrainingError extends TrainingState {
  final String message;
  const TrainingError(this.message);
  @override
  List<Object?> get props => [message];
}
