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

class OnboardingTask extends Equatable {
  final String id;
  final String title;
  final bool completed;

  const OnboardingTask({
    required this.id,
    required this.title,
    required this.completed,
  });

  OnboardingTask copyWith({bool? completed}) {
    return OnboardingTask(
      id: id,
      title: title,
      completed: completed ?? this.completed,
    );
  }

  @override
  List<Object?> get props => [id, title, completed];
}

class NewHireOnboarding extends Equatable {
  final String id;
  final String hireName;
  final String startDate;
  final List<OnboardingTask> tasks;

  const NewHireOnboarding({
    required this.id,
    required this.hireName,
    required this.startDate,
    required this.tasks,
  });

  double get completionPercent {
    if (tasks.isEmpty) return 1.0;
    final completedCount = tasks.where((t) => t.completed).length;
    return completedCount / tasks.length;
  }

  NewHireOnboarding copyWith({
    String? id,
    String? hireName,
    String? startDate,
    List<OnboardingTask>? tasks,
  }) {
    return NewHireOnboarding(
      id: id ?? this.id,
      hireName: hireName ?? this.hireName,
      startDate: startDate ?? this.startDate,
      tasks: tasks ?? this.tasks,
    );
  }

  @override
  List<Object?> get props => [id, hireName, startDate, tasks];
}
