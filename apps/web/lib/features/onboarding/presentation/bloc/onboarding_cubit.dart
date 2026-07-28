import 'package:hr_core/features/admin/domain/entities/recruitment_entities.dart';
import 'package:hr_core/features/admin/domain/repositories/recruitment_repository.dart';
import '../../../../core/bloc/web_cubits.dart';

class OnboardingCubit extends WebCubit<List<NewHireOnboarding>> {
  final RecruitmentRepository _repo;
  OnboardingCubit(this._repo) : super(() => _repo.getOnboardingRecords());

  Future<void> toggleTask(String recordId, String taskId) async {
    await _repo.toggleOnboardingTask(recordId, taskId);
    load();
  }
}

