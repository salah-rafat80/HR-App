import 'package:hr_core/features/appraisal/domain/entities/appraisal_entities.dart';
import 'package:hr_core/features/appraisal/domain/repositories/appraisal_repository.dart';
import '../../../../core/bloc/web_cubits.dart';

class AppraisalCubit extends WebCubit<AppraisalCycle> {
  final AppraisalRepository _repo;

  AppraisalCubit(this._repo) : super(() => _repo.getCurrentCycle());

  Future<void> startNewCycle(String label, DateTime dueDate) async {
    await _repo.startNewCycle(label, dueDate);
    load();
  }
}
