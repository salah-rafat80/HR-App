import '../../domain/entities/offboarding_entities.dart';

class FakeOffboardingDataSource {
  final List<OffboardingCase> _cases = [
    const OffboardingCase(
      id: 'offb_1',
      employeeName: 'John Doe',
      lastWorkingDay: '2026-07-31',
      status: 'inProgress',
      tasks: [
        OffboardingTask(id: 't_1', title: 'Revoke system access', completed: true),
        OffboardingTask(id: 't_2', title: 'Return company assets', completed: false),
        OffboardingTask(id: 't_3', title: 'Exit interview', completed: true),
        OffboardingTask(id: 't_4', title: 'Final settlement processed', completed: false),
        OffboardingTask(id: 't_5', title: 'Update org chart', completed: false),
      ],
    ),
  ];

  Future<List<OffboardingCase>> getOffboardingCases() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _cases;
  }

  Future<void> initiateOffboarding(String employeeName, String lastWorkingDay) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _cases.insert(
      0,
      OffboardingCase(
        id: 'offb_${DateTime.now().millisecondsSinceEpoch}',
        employeeName: employeeName,
        lastWorkingDay: lastWorkingDay,
        status: 'initiated',
        tasks: const [
          OffboardingTask(id: 't_1', title: 'Revoke system access', completed: false),
          OffboardingTask(id: 't_2', title: 'Return company assets', completed: false),
          OffboardingTask(id: 't_3', title: 'Exit interview', completed: false),
          OffboardingTask(id: 't_4', title: 'Final settlement processed', completed: false),
          OffboardingTask(id: 't_5', title: 'Update org chart', completed: false),
        ],
      ),
    );
  }

  Future<void> toggleOffboardingTask(String caseId, String taskId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final caseIndex = _cases.indexWhere((c) => c.id == caseId);
    if (caseIndex != -1) {
      final c = _cases[caseIndex];
      final taskIndex = c.tasks.indexWhere((t) => t.id == taskId);
      if (taskIndex != -1) {
        final updatedTasks = List<OffboardingTask>.from(c.tasks);
        final currentTask = updatedTasks[taskIndex];
        updatedTasks[taskIndex] = currentTask.copyWith(completed: !currentTask.completed);

        final allCompleted = updatedTasks.every((t) => t.completed);
        final anyCompleted = updatedTasks.any((t) => t.completed);
        String newStatus = c.status;
        if (allCompleted) {
          newStatus = 'completed';
        } else if (anyCompleted) {
          newStatus = 'inProgress';
        }

        _cases[caseIndex] = c.copyWith(tasks: updatedTasks, status: newStatus);
      }
    }
  }
}
