import 'package:flutter_bloc/flutter_bloc.dart';
import 'training_state.dart';
import '../../domain/repositories/training_repository.dart';

class TrainingCubit extends Cubit<TrainingState> {
  final TrainingRepository _repository;

  TrainingCubit(this._repository) : super(TrainingInitial());

  Future<void> loadData() async {
    if (!isClosed) { emit(TrainingLoading()); }
    try {
      final available = await _repository.getAvailableCourses();
      final enrolled = await _repository.getMyEnrollments();
      final certs = await _repository.getCertifications();
      final pending = await _repository.getPendingMandatoryCourses();
      
      if (!isClosed) { emit(TrainingLoaded(
        availableCourses: available,
        myEnrollments: enrolled,
        certifications: certs,
        pendingMandatory: pending,
      )); }
    } catch (e) {
      if (!isClosed) { emit(TrainingError(e.toString())); }
    }
  }

  Future<void> enroll(String courseId) async {
    if (state is! TrainingLoaded) return;
    final currentState = state as TrainingLoaded;
    if (!isClosed) { emit(currentState.copyWith(isEnrolling: true, enrollError: null)); }
    try {
      await _repository.enroll(courseId);
      final available = await _repository.getAvailableCourses();
      final enrolled = await _repository.getMyEnrollments();
      final pending = await _repository.getPendingMandatoryCourses();
      
      if (!isClosed) { emit(currentState.copyWith(
        isEnrolling: false,
        availableCourses: available,
        myEnrollments: enrolled,
        pendingMandatory: pending,
      )); }
    } catch (e) {
      if (!isClosed) { emit(currentState.copyWith(isEnrolling: false, enrollError: e.toString())); }
    }
  }
}
