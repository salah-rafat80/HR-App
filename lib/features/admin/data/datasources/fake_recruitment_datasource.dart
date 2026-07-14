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

  Future<List<JobRequisition>> getJobRequisitions() async {
    await Future.delayed(const Duration(milliseconds: 500));
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
    }
  }

  Future<void> generateOffer(String candidateId) async {
    await Future.delayed(const Duration(milliseconds: 600));
    // Simulated success
  }
}
