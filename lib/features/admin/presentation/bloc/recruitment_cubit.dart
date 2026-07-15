import 'package:hr_app_demo/core/utils/safe_cubit.dart';
import '../../domain/entities/recruitment_entities.dart';
import '../../domain/repositories/recruitment_repository.dart';

abstract class RecruitmentState {}

class RecruitmentInitial extends RecruitmentState {}
class RecruitmentLoading extends RecruitmentState {}
class RecruitmentLoaded extends RecruitmentState {
  final List<JobRequisition> jobs;
  final Map<String, List<Candidate>> candidatesMap;
  final List<NewHireOnboarding> onboardingRecords;
  RecruitmentLoaded(this.jobs, this.candidatesMap, this.onboardingRecords);
}
class RecruitmentError extends RecruitmentState {
  final String message;
  RecruitmentError(this.message);
}

class RecruitmentCubit extends SafeCubit<RecruitmentState> {
  final RecruitmentRepository _repository;

  RecruitmentCubit(this._repository) : super(RecruitmentInitial());

  Future<void> fetchData() async {
    emit(RecruitmentLoading());
    try {
      final jobs = await _repository.getJobRequisitions();
      final candidatesMap = <String, List<Candidate>>{};
      for (final job in jobs) {
        final c = await _repository.getCandidates(job.id);
        candidatesMap[job.id] = c;
      }
      final onboardingRecords = await _repository.getOnboardingRecords();
      emit(RecruitmentLoaded(jobs, candidatesMap, onboardingRecords));
    } catch (e) {
      emit(RecruitmentError(e.toString()));
    }
  }

  Future<void> postJob(JobRequisition draft) async {
    try {
      await _repository.postJob(draft);
      fetchData();
    } catch (e) {
      emit(RecruitmentError(e.toString()));
    }
  }

  Future<void> moveCandidateStage(String candidateId, CandidateStage newStage) async {
    try {
      await _repository.moveCandidateStage(candidateId, newStage);
      fetchData();
    } catch (e) {
      emit(RecruitmentError(e.toString()));
    }
  }

  Future<void> generateOffer(String candidateId) async {
    try {
      await _repository.generateOffer(candidateId);
      // Optional: re-fetch or just show toast in UI
    } catch (e) {
      emit(RecruitmentError(e.toString()));
    }
  }

  Future<void> toggleOnboardingTask(String recordId, String taskId) async {
    try {
      await _repository.toggleOnboardingTask(recordId, taskId);
      fetchData();
    } catch (e) {
      emit(RecruitmentError(e.toString()));
    }
  }
}
