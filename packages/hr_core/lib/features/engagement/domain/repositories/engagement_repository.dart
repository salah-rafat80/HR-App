import '../entities/engagement_entities.dart';

abstract class EngagementRepository {
  Future<PulseSurveyPrompt> getWeeklyPulseSurvey();
  Future<void> submitPulseAnswer(int answer);
  
  Future<EnpsPrompt> getEnpsPrompt();
  Future<void> submitEnpsScore(int score);
  
  Future<List<RecognitionBadge>> getRecognitionFeed();
  Future<void> giveRecognition(String toName, String badgeType, String message);
  
  Future<int> getMyPoints();
  Future<List<RewardItem>> getRewardCatalog();
  Future<void> redeemReward(String itemId);
  
  Future<double> getEngagementScorePercent();
}
