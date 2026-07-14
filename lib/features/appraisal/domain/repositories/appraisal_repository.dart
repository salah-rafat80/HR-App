import '../entities/appraisal_entities.dart';

abstract class AppraisalRepository {
  Future<AppraisalCycle> getCurrentCycle();
  Future<List<SelfAppraisalQuestion>> getSelfAppraisalQuestions();
  Future<void> submitSelfAppraisal(List<SelfAppraisalQuestion> answers);
  Future<List<PeerFeedback>> getPeersForFeedback();
  Future<void> submitPeerFeedback(String colleagueId, String text);
  Future<AppraisalResult> getMyResults();
  Future<List<DevelopmentGoal>> getDevelopmentPlan();
  Future<List<CareerStep>> getCareerPath();
}
