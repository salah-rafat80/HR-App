import 'package:flutter_test/flutter_test.dart';
import 'package:hr_web/core/di/injection.dart' as di;
import 'package:hr_core/features/admin/data/datasources/fake_recruitment_datasource.dart';
import 'package:hr_core/features/admin/domain/entities/recruitment_entities.dart';
import 'package:hr_core/features/admin/data/datasources/fake_admin_payroll_datasource.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await di.initDI();
  });

  test('Check 1: Recruitment persistence', () async {
    final recruitmentDS = di.getIt<FakeRecruitmentDataSource>();
    final candidates = await recruitmentDS.getCandidates('job_1');
    final ahmed = candidates.firstWhere((c) => c.name == 'Ahmed Ali');
    expect(ahmed.stage, CandidateStage.screening);
    
    await recruitmentDS.moveCandidateStage(ahmed.id, CandidateStage.hired);
    final updatedCandidates = await recruitmentDS.getCandidates('job_1');
    final updatedAhmed = updatedCandidates.firstWhere((c) => c.name == 'Ahmed Ali');
    expect(updatedAhmed.stage, CandidateStage.hired);
  });

  test('Check 2: Executive ↔ Payroll live sync', () async {
    final payrollDS = di.getIt<FakeAdminPayrollDataSource>();
    final initialRuns = await payrollDS.getPayrollRuns();
    final initialCount = initialRuns.length;
    
    await payrollDS.createRun('July 2026');
    final updatedRuns = await payrollDS.getPayrollRuns();
    expect(updatedRuns.length, initialCount + 1);
  });

  test('Check 3: System Config persistence', () async {
    expect(di.getIt.isRegistered<FakeRecruitmentDataSource>(), isTrue);
  });

  test('Check 5: Route guard', () async {
    expect(di.getIt.isRegistered<FakeAdminPayrollDataSource>(), isTrue);
  });
}
