import 'package:equatable/equatable.dart';

class OffboardingTask extends Equatable {
  final String id;
  final String title;
  final bool completed;

  const OffboardingTask({
    required this.id,
    required this.title,
    required this.completed,
  });

  OffboardingTask copyWith({bool? completed}) {
    return OffboardingTask(
      id: id,
      title: title,
      completed: completed ?? this.completed,
    );
  }

  @override
  List<Object?> get props => [id, title, completed];
}

class OffboardingCase extends Equatable {
  final String id;
  final String employeeName;
  final String lastWorkingDay;
  final String status; // initiated, inProgress, completed
  final List<OffboardingTask> tasks;

  const OffboardingCase({
    required this.id,
    required this.employeeName,
    required this.lastWorkingDay,
    required this.status,
    required this.tasks,
  });

  double get completionPercent {
    if (tasks.isEmpty) return 1.0;
    final completedCount = tasks.where((t) => t.completed).length;
    return completedCount / tasks.length;
  }

  OffboardingCase copyWith({
    String? id,
    String? employeeName,
    String? lastWorkingDay,
    String? status,
    List<OffboardingTask>? tasks,
  }) {
    return OffboardingCase(
      id: id ?? this.id,
      employeeName: employeeName ?? this.employeeName,
      lastWorkingDay: lastWorkingDay ?? this.lastWorkingDay,
      status: status ?? this.status,
      tasks: tasks ?? this.tasks,
    );
  }

  @override
  List<Object?> get props => [id, employeeName, lastWorkingDay, status, tasks];
}
