import '../../domain/entities/training_entities.dart';
import '../../domain/repositories/training_repository.dart';
import '../datasources/fake_training_datasource.dart';

class TrainingRepositoryImpl implements TrainingRepository {
  final FakeTrainingDataSource _dataSource;

  TrainingRepositoryImpl(this._dataSource);

  @override
  Future<void> enroll(String courseId) => _dataSource.enroll(courseId);

  @override
  Future<List<TrainingCourse>> getAvailableCourses() => _dataSource.getAvailableCourses();

  @override
  Future<List<Certification>> getCertifications() => _dataSource.getCertifications();

  @override
  Future<List<TrainingCourse>> getMyEnrollments() => _dataSource.getMyEnrollments();

  @override
  Future<List<TrainingCourse>> getPendingMandatoryCourses() => _dataSource.getPendingMandatoryCourses();

  @override
  Future<void> updateProgress(String courseId, double percent) => _dataSource.updateProgress(courseId, percent);
}
