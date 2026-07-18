import '../entities/training_entities.dart';

abstract class TrainingRepository {
  Future<List<TrainingCourse>> getAvailableCourses();
  Future<List<TrainingCourse>> getMyEnrollments();
  Future<void> enroll(String courseId);
  Future<void> updateProgress(String courseId, double percent);
  Future<List<Certification>> getCertifications();
  Future<List<TrainingCourse>> getPendingMandatoryCourses();
}
