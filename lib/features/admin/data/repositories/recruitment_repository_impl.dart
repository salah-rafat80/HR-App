import '../../domain/entities/recruitment_entities.dart';
import '../../domain/repositories/recruitment_repository.dart';
import '../datasources/fake_recruitment_datasource.dart';

class RecruitmentRepositoryImpl implements RecruitmentRepository {
  final FakeRecruitmentDataSource _dataSource;

  RecruitmentRepositoryImpl(this._dataSource);

  @override
  Future<void> generateOffer(String candidateId) => _dataSource.generateOffer(candidateId);

  @override
  Future<List<Candidate>> getCandidates(String jobId) => _dataSource.getCandidates(jobId);

  @override
  Future<List<JobRequisition>> getJobRequisitions() => _dataSource.getJobRequisitions();

  @override
  Future<void> moveCandidateStage(String candidateId, CandidateStage newStage) => _dataSource.moveCandidateStage(candidateId, newStage);

  @override
  Future<void> postJob(JobRequisition draft) => _dataSource.postJob(draft);
}
