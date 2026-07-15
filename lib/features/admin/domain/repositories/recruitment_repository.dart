import '../entities/recruitment_entities.dart';

abstract class RecruitmentRepository {
  Future<List<JobRequisition>> getJobRequisitions();
  Future<void> postJob(JobRequisition draft);
  Future<List<Candidate>> getCandidates(String jobId);
  Future<void> moveCandidateStage(String candidateId, CandidateStage newStage);
  Future<void> generateOffer(String candidateId);
  Future<List<NewHireOnboarding>> getOnboardingRecords();
  Future<void> toggleOnboardingTask(String recordId, String taskId);
}
