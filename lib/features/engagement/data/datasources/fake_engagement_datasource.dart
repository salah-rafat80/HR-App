import '../../domain/entities/engagement_entities.dart';

class FakeEngagementDataSource {
  PulseSurveyPrompt _currentPulse = const PulseSurveyPrompt(
    id: 'p_1',
    weekLabel: 'Week 32',
    questionText: 'How supported do you feel by your team this week?',
  );

  EnpsPrompt _currentEnps = const EnpsPrompt(
    id: 'e_1',
    questionText: 'On a scale from 0-10, how likely are you to recommend our company as a great place to work?',
  );

  final List<RecognitionBadge> _feed = [
    const RecognitionBadge(
      id: 'r_1',
      fromName: 'Ahmed Ali',
      toName: 'Sara Kamel',
      badgeType: 'Team Player',
      message: 'Thanks for helping with the deployment yesterday!',
      pointsAwarded: 50,
    ),
    const RecognitionBadge(
      id: 'r_2',
      fromName: 'Omar Hassan',
      toName: 'Nour Tariq',
      badgeType: 'Innovator',
      message: 'Great idea on the new architecture design.',
      pointsAwarded: 100,
    ),
    const RecognitionBadge(
      id: 'r_3',
      fromName: 'Fatma Youssef',
      toName: 'Ahmed Ali',
      badgeType: 'Great Mentor',
      message: 'Appreciate the time you took to explain the codebase.',
      pointsAwarded: 75,
    ),
  ];

  int _myPoints = 320;

  final List<RewardItem> _rewards = [
    const RewardItem(id: 'rw_1', name: 'Coffee Shop \$10 Gift Card', pointsCost: 100),
    const RewardItem(id: 'rw_2', name: 'Company Swag T-Shirt', pointsCost: 250),
    const RewardItem(id: 'rw_3', name: 'Extra Day Off', pointsCost: 2000),
    const RewardItem(id: 'rw_4', name: 'Lunch with CEO', pointsCost: 1000),
  ];

  Future<PulseSurveyPrompt> getWeeklyPulseSurvey() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _currentPulse;
  }

  Future<void> submitPulseAnswer(int answer) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentPulse = _currentPulse.copyWith(answer: answer);
  }

  Future<EnpsPrompt> getEnpsPrompt() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _currentEnps;
  }

  Future<void> submitEnpsScore(int score) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentEnps = _currentEnps.copyWith(answer: score);
  }

  Future<List<RecognitionBadge>> getRecognitionFeed() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _feed;
  }

  Future<void> giveRecognition(String toName, String badgeType, String message) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _feed.insert(0, RecognitionBadge(
      id: 'r_${DateTime.now().millisecondsSinceEpoch}',
      fromName: 'Current User',
      toName: toName,
      badgeType: badgeType,
      message: message,
      pointsAwarded: 50,
    ));
    _myPoints += 50; // award points to giver as requested
  }

  Future<int> getMyPoints() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _myPoints;
  }

  Future<List<RewardItem>> getRewardCatalog() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _rewards;
  }

  Future<void> redeemReward(String itemId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final reward = _rewards.firstWhere((r) => r.id == itemId);
    if (_myPoints >= reward.pointsCost) {
      _myPoints -= reward.pointsCost;
    } else {
      throw Exception('Not enough points to redeem this reward.');
    }
  }

  Future<double> getEngagementScorePercent() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return 0.76; // 76%
  }
}
