import '../../domain/entities/training_entities.dart';

class FakeTrainingDataSource {
  final List<TrainingCourse> _courses = [
    const TrainingCourse(id: 't1', title: 'Advanced Flutter Patterns', category: TrainingCategory.technical, durationHours: 12),
    const TrainingCourse(id: 't2', title: 'Effective Communication', category: TrainingCategory.softSkills, durationHours: 4),
    const TrainingCourse(id: 't3', title: 'Data Privacy & Compliance 101', category: TrainingCategory.compliance, durationHours: 2, isMandatory: true),
    const TrainingCourse(id: 't4', title: 'Leading Remote Teams', category: TrainingCategory.leadership, durationHours: 6),
    const TrainingCourse(id: 't5', title: 'Workplace Safety Guidelines', category: TrainingCategory.compliance, durationHours: 1, isMandatory: true),
    const TrainingCourse(id: 't6', title: 'Mastering Dart Async', category: TrainingCategory.technical, durationHours: 8, isEnrolled: true, progressPercent: 0.4),
    const TrainingCourse(id: 't7', title: 'Conflict Resolution', category: TrainingCategory.softSkills, durationHours: 3, isEnrolled: true, progressPercent: 0.7),
  ];

  final List<Certification> _certs = [
    Certification(title: 'Flutter Certified Developer', dateEarned: DateTime.now().subtract(const Duration(days: 120))),
    Certification(title: 'Agile Fundamentals', dateEarned: DateTime.now().subtract(const Duration(days: 300))),
  ];

  Future<List<TrainingCourse>> getAvailableCourses() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _courses.where((c) => !c.isEnrolled).toList();
  }

  Future<List<TrainingCourse>> getMyEnrollments() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _courses.where((c) => c.isEnrolled).toList();
  }

  Future<void> enroll(String courseId) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final index = _courses.indexWhere((c) => c.id == courseId);
    if (index != -1) {
      _courses[index] = _courses[index].copyWith(isEnrolled: true);
    }
  }

  Future<void> updateProgress(String courseId, double percent) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _courses.indexWhere((c) => c.id == courseId);
    if (index != -1) {
      _courses[index] = _courses[index].copyWith(progressPercent: percent);
    }
  }

  Future<List<Certification>> getCertifications() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _certs;
  }

  Future<List<TrainingCourse>> getPendingMandatoryCourses() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _courses.where((c) => c.isMandatory && !c.isEnrolled).toList();
  }
}
