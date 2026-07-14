import '../../domain/entities/appraisal_entities.dart';

class FakeAppraisalDataSource {
  AppraisalCycle _currentCycle = AppraisalCycle(
    cycleLabel: 'Q2 2026 Review',
    status: AppraisalStatus.inProgress,
    dueDate: DateTime.now().add(const Duration(days: 14)),
  );

  final List<SelfAppraisalQuestion> _questions = [
    const SelfAppraisalQuestion(id: 'q1', questionText: 'What were your key achievements this cycle?'),
    const SelfAppraisalQuestion(id: 'q2', questionText: 'What challenges did you face?'),
    const SelfAppraisalQuestion(id: 'q3', questionText: 'How did you live our core values?'),
    const SelfAppraisalQuestion(id: 'q4', questionText: 'What support do you need going forward?'),
    const SelfAppraisalQuestion(id: 'q5', questionText: 'What are your goals for the next cycle?'),
  ];

  final List<PeerFeedback> _peers = [
    const PeerFeedback(colleague: Colleague(id: 'c1', name: 'Sara Ahmed', role: 'UX Designer', avatarInitial: 'S'), submitted: true, feedbackText: 'Great teamwork.'),
    const PeerFeedback(colleague: Colleague(id: 'c2', name: 'Omar Ali', role: 'Backend Dev', avatarInitial: 'O')),
    const PeerFeedback(colleague: Colleague(id: 'c3', name: 'Mona Zaki', role: 'Product Manager', avatarInitial: 'M')),
  ];

  final AppraisalResult _myResults = const AppraisalResult(
    overallRating: 4.2,
    categoryRatings: [
      AppraisalCategoryRating(categoryName: 'Communication', score: 4.5, managerComment: 'Clear and proactive.'),
      AppraisalCategoryRating(categoryName: 'Technical Skill', score: 4.0, managerComment: 'Solid performance.'),
      AppraisalCategoryRating(categoryName: 'Teamwork', score: 4.8, managerComment: 'Excellent collaboration.'),
      AppraisalCategoryRating(categoryName: 'Ownership', score: 3.5, managerComment: 'Good, but needs more initiative.'),
    ],
    managerSummary: 'A very strong quarter. Keep up the good work and focus on taking more ownership of end-to-end features.',
  );

  final List<DevelopmentGoal> _devPlan = [
    const DevelopmentGoal(title: 'Master Flutter Animations', progressPercent: 0.6),
    const DevelopmentGoal(title: 'Lead a technical deep-dive', progressPercent: 0.2),
    const DevelopmentGoal(title: 'Improve test coverage in core module', progressPercent: 0.9),
  ];

  final List<CareerStep> _careerPath = [
    const CareerStep(roleTitle: 'Junior Developer', status: CareerStepStatus.completed),
    const CareerStep(roleTitle: 'Mid-Level Developer', status: CareerStepStatus.completed),
    const CareerStep(roleTitle: 'Senior Developer', status: CareerStepStatus.current),
    const CareerStep(roleTitle: 'Tech Lead', status: CareerStepStatus.upcoming),
    const CareerStep(roleTitle: 'Engineering Manager', status: CareerStepStatus.upcoming),
  ];

  Future<AppraisalCycle> getCurrentCycle() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _currentCycle;
  }

  Future<List<SelfAppraisalQuestion>> getSelfAppraisalQuestions() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _questions;
  }

  Future<void> submitSelfAppraisal(List<SelfAppraisalQuestion> answers) async {
    await Future.delayed(const Duration(milliseconds: 800));
    _currentCycle = _currentCycle.copyWith(selfAppraisalSubmitted: true);
    // In a real app we'd save the answers. For fake, just mark submitted.
  }

  Future<List<PeerFeedback>> getPeersForFeedback() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _peers;
  }

  Future<void> submitPeerFeedback(String colleagueId, String text) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final idx = _peers.indexWhere((p) => p.colleague.id == colleagueId);
    if (idx != -1) {
      _peers[idx] = _peers[idx].copyWith(submitted: true, feedbackText: text);
    }
  }

  Future<AppraisalResult> getMyResults() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _myResults;
  }

  Future<List<DevelopmentGoal>> getDevelopmentPlan() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _devPlan;
  }

  Future<List<CareerStep>> getCareerPath() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _careerPath;
  }

  Future<void> startNewCycle(String label, DateTime dueDate) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _currentCycle = AppraisalCycle(
      cycleLabel: label,
      status: AppraisalStatus.inProgress,
      dueDate: dueDate,
    );
  }
}
