import 'package:equatable/equatable.dart';

enum CandidateStage { applied, screening, interview, offer, hired, rejected }

class Candidate extends Equatable {
  final String id;
  final String name;
  final String jobId;
  final CandidateStage stage;

  const Candidate({
    required this.id,
    required this.name,
    required this.jobId,
    required this.stage,
  });

  Candidate copyWith({CandidateStage? stage}) {
    return Candidate(
      id: id,
      name: name,
      jobId: jobId,
      stage: stage ?? this.stage,
    );
  }

  @override
  List<Object?> get props => [id, name, jobId, stage];
}

class JobRequisition extends Equatable {
  final String id;
  final String title;
  final String department;
  final String status; // 'open', 'closed'
  final int openings;

  const JobRequisition({
    required this.id,
    required this.title,
    required this.department,
    required this.status,
    required this.openings,
  });

  @override
  List<Object?> get props => [id, title, department, status, openings];
}
