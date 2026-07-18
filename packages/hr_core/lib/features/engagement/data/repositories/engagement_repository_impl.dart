import '../../domain/entities/engagement_entities.dart';
import '../../domain/repositories/engagement_repository.dart';
import '../datasources/fake_engagement_datasource.dart';

class EngagementRepositoryImpl implements EngagementRepository {
  final FakeEngagementDataSource _dataSource;

  EngagementRepositoryImpl(this._dataSource);

  @override
  Future<PulseSurveyPrompt> getWeeklyPulseSurvey() => _dataSource.getWeeklyPulseSurvey();

  @override
  Future<void> submitPulseAnswer(int answer) => _dataSource.submitPulseAnswer(answer);

  @override
  Future<EnpsPrompt> getEnpsPrompt() => _dataSource.getEnpsPrompt();

  @override
  Future<void> submitEnpsScore(int score) => _dataSource.submitEnpsScore(score);

  @override
  Future<List<RecognitionBadge>> getRecognitionFeed() => _dataSource.getRecognitionFeed();

  @override
  Future<void> giveRecognition(String toName, String badgeType, String message) => _dataSource.giveRecognition(toName, badgeType, message);

  @override
  Future<int> getMyPoints() => _dataSource.getMyPoints();

  @override
  Future<List<RewardItem>> getRewardCatalog() => _dataSource.getRewardCatalog();

  @override
  Future<void> redeemReward(String itemId) => _dataSource.redeemReward(itemId);

  @override
  Future<double> getEngagementScorePercent() => _dataSource.getEngagementScorePercent();
}
