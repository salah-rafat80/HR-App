import '../../domain/entities/recruitment_entities.dart';

class FakeRecruitmentDataSource {
  final List<JobRequisition> _jobs = [
    const JobRequisition(id: 'job_1', title: 'Senior Flutter Developer', department: 'Engineering', status: 'open', openings: 2),
    const JobRequisition(id: 'job_2', title: 'HR Business Partner', department: 'HR', status: 'open', openings: 1),
    const JobRequisition(id: 'job_3', title: 'Sales Executive', department: 'Sales', status: 'open', openings: 3),
  ];

  final List<Candidate> _candidates = [
    const Candidate(id: 'c_1', name: 'Ahmed Ali', jobId: 'job_1', stage: CandidateStage.screening),
    const Candidate(id: 'c_2', name: 'Sara Kamel', jobId: 'job_1', stage: CandidateStage.interview),
    const Candidate(id: 'c_3', name: 'Nour Hassan', jobId: 'job_1', stage: CandidateStage.offer),
    const Candidate(id: 'c_4', name: 'Mona Youssef', jobId: 'job_2', stage: CandidateStage.applied),
    const Candidate(id: 'c_5', name: 'Tariq Omar', jobId: 'job_2', stage: CandidateStage.screening),
    const Candidate(id: 'c_6', name: 'Ziad Mahmoud', jobId: 'job_3', stage: CandidateStage.hired),
  ];

  final List<NewHireOnboarding> _onboardingRecords = [
    const NewHireOnboarding(
      id: 'onb_1',
      hireName: 'Ziad Mahmoud',
      startDate: '2026-08-01',
      tasks: [
        OnboardingTask(id: 't_1', title: 'Sign contract', completed: true),
        OnboardingTask(id: 't_2', title: 'IT equipment setup', completed: true),
        OnboardingTask(id: 't_3', title: 'Complete compliance training', completed: false),
        OnboardingTask(id: 't_4', title: 'Meet the team', completed: false),
        OnboardingTask(id: 't_5', title: 'HR orientation session', completed: false),
      ],
    ),
    const NewHireOnboarding(
      id: 'onb_2',
      hireName: 'Amira Khaled',
      startDate: '2026-07-20',
      tasks: [
        OnboardingTask(id: 't_1', title: 'Sign contract', completed: true),
        OnboardingTask(id: 't_2', title: 'IT equipment setup', completed: true),
        OnboardingTask(id: 't_3', title: 'Complete compliance training', completed: true),
        OnboardingTask(id: 't_4', title: 'Meet the team', completed: true),
        OnboardingTask(id: 't_5', title: 'HR orientation session', completed: false),
      ],
    ),
  ];

  Future<List<JobRequisition>> getJobRequisitions() async {    await Future.delayed(const Duration(milliseconds: 500));
    return _jobs;
  }

  Future<void> postJob(JobRequisition draft) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _jobs.insert(0, draft);
  }

  Future<List<Candidate>> getCandidates(String jobId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _candidates.where((c) => c.jobId == jobId).toList();
  }

  Future<void> moveCandidateStage(String candidateId, CandidateStage newStage) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _candidates.indexWhere((c) => c.id == candidateId);
    if (index != -1) {
      _candidates[index] = _candidates[index].copyWith(stage: newStage);
      if (newStage == CandidateStage.hired) {
        _onboardingRecords.add(
          NewHireOnboarding(
            id: 'onb_${DateTime.now().millisecondsSinceEpoch}',
            hireName: _candidates[index].name,
            startDate: DateTime.now().add(const Duration(days: 14)).toIso8601String().split('T').first,
            tasks: const [
              OnboardingTask(id: 't_1', title: 'Sign contract', completed: false),
              OnboardingTask(id: 't_2', title: 'IT equipment setup', completed: false),
              OnboardingTask(id: 't_3', title: 'Complete compliance training', completed: false),
              OnboardingTask(id: 't_4', title: 'Meet the team', completed: false),
              OnboardingTask(id: 't_5', title: 'HR orientation session', completed: false),
            ],
          ),
        );
      }
    }
  }

  Future<void> generateOffer(String candidateId) async {
    await Future.delayed(const Duration(milliseconds: 600));
    // Simulated success
  }

  Future<List<NewHireOnboarding>> getOnboardingRecords() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _onboardingRecords;
  }

  Future<void> toggleOnboardingTask(String recordId, String taskId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final recordIndex = _onboardingRecords.indexWhere((r) => r.id == recordId);
    if (recordIndex != -1) {
      final record = _onboardingRecords[recordIndex];
      final taskIndex = record.tasks.indexWhere((t) => t.id == taskId);
      if (taskIndex != -1) {
        final updatedTasks = List<OnboardingTask>.from(record.tasks);
        final currentTask = updatedTasks[taskIndex];
        updatedTasks[taskIndex] = currentTask.copyWith(completed: !currentTask.completed);
        _onboardingRecords[recordIndex] = record.copyWith(tasks: updatedTasks);
      }
    }
  }
}
