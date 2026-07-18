import '../../domain/entities/appraisal_entities.dart';
import '../../domain/repositories/appraisal_repository.dart';
import '../datasources/fake_appraisal_datasource.dart';

class AppraisalRepositoryImpl implements AppraisalRepository {
  final FakeAppraisalDataSource _dataSource;

  AppraisalRepositoryImpl(this._dataSource);

  @override
  Future<List<CareerStep>> getCareerPath() => _dataSource.getCareerPath();

  @override
  Future<AppraisalCycle> getCurrentCycle() => _dataSource.getCurrentCycle();

  @override
  Future<List<DevelopmentGoal>> getDevelopmentPlan() => _dataSource.getDevelopmentPlan();

  @override
  Future<AppraisalResult> getMyResults() => _dataSource.getMyResults();

  @override
  Future<List<PeerFeedback>> getPeersForFeedback() => _dataSource.getPeersForFeedback();

  @override
  Future<List<SelfAppraisalQuestion>> getSelfAppraisalQuestions() => _dataSource.getSelfAppraisalQuestions();

  @override
  Future<void> submitPeerFeedback(String colleagueId, String text) => _dataSource.submitPeerFeedback(colleagueId, text);

  @override
  Future<void> submitSelfAppraisal(List<SelfAppraisalQuestion> answers) => _dataSource.submitSelfAppraisal(answers);

  @override
  Future<void> startNewCycle(String label, DateTime dueDate) => _dataSource.startNewCycle(label, dueDate);
}
