import '../entities/offboarding_entities.dart';

abstract class OffboardingRepository {
  Future<List<OffboardingCase>> getOffboardingCases();
  Future<void> initiateOffboarding(String employeeName, String lastWorkingDay);
  Future<void> toggleOffboardingTask(String caseId, String taskId);
}
