import 'package:hr_core/features/admin/domain/entities/offboarding_entities.dart';
import 'package:hr_core/features/admin/domain/repositories/offboarding_repository.dart';
import '../../../../core/bloc/web_cubits.dart';

class OffboardingCubit extends WebCubit<List<OffboardingCase>> {
  final OffboardingRepository _repo;
  OffboardingCubit(this._repo) : super(() => _repo.getOffboardingCases());

  Future<void> toggleTask(String caseId, String taskId) async {
    await _repo.toggleOffboardingTask(caseId, taskId);
    load();
  }
}
