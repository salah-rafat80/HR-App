import 'package:dio/dio.dart';
import '../../domain/entities/appraisal_entities.dart';
import '../../domain/repositories/appraisal_repository.dart';

class ApiAppraisalRepositoryImpl implements AppraisalRepository {
  final Dio dio;

  ApiAppraisalRepositoryImpl({required this.dio});

  @override
  Future<AppraisalCycle> getCurrentCycle() async {
    final response = await dio.get('/appraisal/cycle/current');
    return AppraisalCycle.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<SelfAppraisalQuestion>> getSelfAppraisalQuestions() async {
    final response = await dio.get('/appraisal/self-appraisal/questions');
    return (response.data as List)
        .map((e) => SelfAppraisalQuestion.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> submitSelfAppraisal(List<SelfAppraisalQuestion> answers) async {
    await dio.post(
      '/appraisal/self-appraisal/submit',
      data: {
        'answers': answers.map((e) => e.toJson()).toList(),
      },
    );
  }

  @override
  Future<List<PeerFeedback>> getPeersForFeedback() async {
    final response = await dio.get('/appraisal/peer-feedback/peers');
    return (response.data as List)
        .map((e) => PeerFeedback.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> submitPeerFeedback(String colleagueId, String text) async {
    await dio.post(
      '/appraisal/peer-feedback/submit',
      data: {
        'colleagueId': colleagueId,
        'feedbackText': text,
      },
    );
  }

  @override
  Future<AppraisalResult> getMyResults() async {
    final response = await dio.get('/appraisal/results/my');
    return AppraisalResult.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<DevelopmentGoal>> getDevelopmentPlan() async {
    final response = await dio.get('/appraisal/development-plan');
    return (response.data as List)
        .map((e) => DevelopmentGoal.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<CareerStep>> getCareerPath() async {
    final response = await dio.get('/appraisal/career-path');
    return (response.data as List)
        .map((e) => CareerStep.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> startNewCycle(String label, DateTime dueDate) async {
    await dio.post(
      '/appraisal/cycle/start',
      data: {
        'label': label,
        'dueDate': dueDate.toIso8601String(),
      },
    );
  }
}
