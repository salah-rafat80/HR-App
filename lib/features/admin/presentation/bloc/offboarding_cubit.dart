import 'package:hr_app_demo/core/utils/safe_cubit.dart';
import '../../domain/entities/offboarding_entities.dart';
import '../../domain/repositories/offboarding_repository.dart';

abstract class OffboardingState {}

class OffboardingInitial extends OffboardingState {}
class OffboardingLoading extends OffboardingState {}
class OffboardingLoaded extends OffboardingState {
  final List<OffboardingCase> cases;
  OffboardingLoaded(this.cases);
}
class OffboardingError extends OffboardingState {
  final String message;
  OffboardingError(this.message);
}

class OffboardingCubit extends SafeCubit<OffboardingState> {
  final OffboardingRepository _repository;

  OffboardingCubit(this._repository) : super(OffboardingInitial());

  Future<void> fetchData() async {
    emit(OffboardingLoading());
    try {
      final cases = await _repository.getOffboardingCases();
      emit(OffboardingLoaded(cases));
    } catch (e) {
      emit(OffboardingError(e.toString()));
    }
  }

  Future<void> initiateOffboarding(String employeeName, String lastWorkingDay) async {
    try {
      await _repository.initiateOffboarding(employeeName, lastWorkingDay);
      fetchData();
    } catch (e) {
      emit(OffboardingError(e.toString()));
    }
  }

  Future<void> toggleOffboardingTask(String caseId, String taskId) async {
    try {
      await _repository.toggleOffboardingTask(caseId, taskId);
      fetchData();
    } catch (e) {
      emit(OffboardingError(e.toString()));
    }
  }
}
