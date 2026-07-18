import 'package:hr_app_demo/core/utils/safe_cubit.dart';
import 'package:hr_core/features/engagement/domain/entities/engagement_entities.dart';
import 'package:hr_core/features/engagement/domain/repositories/engagement_repository.dart';

abstract class EngagementState {}

class EngagementInitial extends EngagementState {}
class EngagementLoading extends EngagementState {}
class EngagementLoaded extends EngagementState {
  final PulseSurveyPrompt pulse;
  final EnpsPrompt enps;
  final List<RecognitionBadge> feed;
  final int myPoints;
  final List<RewardItem> rewards;

  EngagementLoaded({
    required this.pulse,
    required this.enps,
    required this.feed,
    required this.myPoints,
    required this.rewards,
  });
}
class EngagementError extends EngagementState {
  final String message;
  EngagementError(this.message);
}

class EngagementCubit extends SafeCubit<EngagementState> {
  final EngagementRepository _repository;

  EngagementCubit(this._repository) : super(EngagementInitial());

  Future<void> fetchData() async {
    emit(EngagementLoading());
    try {
      final pulse = await _repository.getWeeklyPulseSurvey();
      final enps = await _repository.getEnpsPrompt();
      final feed = await _repository.getRecognitionFeed();
      final myPoints = await _repository.getMyPoints();
      final rewards = await _repository.getRewardCatalog();
      
      emit(EngagementLoaded(
        pulse: pulse,
        enps: enps,
        feed: feed,
        myPoints: myPoints,
        rewards: rewards,
      ));
    } catch (e) {
      emit(EngagementError(e.toString()));
    }
  }

  Future<void> submitPulseAnswer(int answer) async {
    try {
      await _repository.submitPulseAnswer(answer);
      fetchData();
    } catch (e) {
      emit(EngagementError(e.toString()));
    }
  }

  Future<void> submitEnpsScore(int score) async {
    try {
      await _repository.submitEnpsScore(score);
      fetchData();
    } catch (e) {
      emit(EngagementError(e.toString()));
    }
  }

  Future<void> giveRecognition(String toName, String badgeType, String message) async {
    try {
      await _repository.giveRecognition(toName, badgeType, message);
      fetchData();
    } catch (e) {
      emit(EngagementError(e.toString()));
    }
  }

  Future<void> redeemReward(String itemId) async {
    try {
      await _repository.redeemReward(itemId);
      fetchData();
    } catch (e) {
      emit(EngagementError(e.toString()));
    }
  }
}
