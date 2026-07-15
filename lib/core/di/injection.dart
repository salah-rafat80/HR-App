import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/theme_cubit.dart';

import '../../features/attendance/data/datasources/fake_attendance_datasource.dart';
import '../../features/attendance/data/repositories/attendance_repository_impl.dart';
import '../../features/attendance/domain/repositories/attendance_repository.dart';
import '../../features/attendance/presentation/bloc/attendance_cubit.dart';
import '../../features/leave/data/datasources/fake_leave_datasource.dart';
import '../../features/leave/data/repositories/leave_repository_impl.dart';
import '../../features/leave/domain/repositories/leave_repository.dart';
import '../../features/leave/presentation/bloc/leave_cubit.dart';
import '../../features/kpi/data/datasources/fake_kpi_datasource.dart';
import '../../features/kpi/data/repositories/kpi_repository_impl.dart';
import '../../features/kpi/domain/repositories/kpi_repository.dart';
import '../../features/kpi/presentation/bloc/kpi_cubit.dart';
import '../../features/appraisal/data/datasources/fake_appraisal_datasource.dart';
import '../../features/appraisal/data/repositories/appraisal_repository_impl.dart';
import '../../features/appraisal/domain/repositories/appraisal_repository.dart';
import '../../features/appraisal/presentation/bloc/appraisal_cubit.dart';
import '../../features/payroll/data/datasources/fake_payroll_datasource.dart';
import '../../features/payroll/data/repositories/payroll_repository_impl.dart';
import '../../features/payroll/domain/repositories/payroll_repository.dart';
import '../../features/payroll/presentation/bloc/payroll_cubit.dart';
import '../../features/training/data/datasources/fake_training_datasource.dart';
import '../../features/training/data/repositories/training_repository_impl.dart';
import '../../features/training/domain/repositories/training_repository.dart';
import '../../features/training/presentation/bloc/training_cubit.dart';
import '../../features/communication/data/datasources/fake_communication_datasource.dart';
import '../../features/communication/data/datasources/fake_it_request_datasource.dart';
import '../../features/communication/data/repositories/communication_repository_impl.dart';
import '../../features/communication/data/repositories/it_request_repository_impl.dart';
import '../../features/communication/domain/repositories/communication_repository.dart';
import '../../features/communication/domain/repositories/it_request_repository.dart';
import '../../features/communication/presentation/bloc/communication_cubit.dart';
import '../../features/home/data/datasources/fake_home_datasource.dart';
import '../../features/home/data/repositories/home_repository_impl.dart';
import '../../features/home/domain/repositories/home_repository.dart';
import '../../features/home/presentation/bloc/home_cubit.dart';
import '../../features/team/presentation/bloc/team_approvals_cubit.dart';
import '../../features/team/presentation/bloc/team_kpi_cubit.dart';
import '../../features/admin/data/datasources/fake_admin_payroll_datasource.dart';
import '../../features/admin/domain/repositories/admin_payroll_repository.dart';
import '../../features/admin/data/repositories/admin_payroll_repository_impl.dart';
import '../../features/admin/presentation/bloc/admin_payroll_cubit.dart';
import '../../features/admin/data/datasources/fake_recruitment_datasource.dart';
import '../../features/admin/domain/repositories/recruitment_repository.dart';
import '../../features/admin/data/repositories/recruitment_repository_impl.dart';
import '../../features/admin/presentation/bloc/recruitment_cubit.dart';
import '../../features/admin/data/datasources/fake_system_config_datasource.dart';
import '../../features/admin/domain/repositories/system_config_repository.dart';
import '../../features/admin/data/repositories/system_config_repository_impl.dart';
import '../../features/admin/presentation/bloc/system_config_cubit.dart';
import '../../features/admin/data/datasources/fake_offboarding_datasource.dart';
import '../../features/admin/domain/repositories/offboarding_repository.dart';
import '../../features/admin/data/repositories/offboarding_repository_impl.dart';
import '../../features/admin/presentation/bloc/offboarding_cubit.dart';
import '../../features/engagement/data/datasources/fake_engagement_datasource.dart';
import '../../features/engagement/domain/repositories/engagement_repository.dart';
import '../../features/engagement/data/repositories/engagement_repository_impl.dart';
import '../../features/engagement/presentation/bloc/engagement_cubit.dart';
import '../../features/org_chart/data/datasources/fake_org_chart_datasource.dart';
import '../../features/org_chart/domain/repositories/org_chart_repository.dart';
import '../../features/org_chart/data/repositories/org_chart_repository_impl.dart';
import '../../features/org_chart/presentation/bloc/org_chart_cubit.dart';
import '../../features/executive/data/datasources/fake_executive_datasource.dart';
import '../../features/executive/domain/repositories/executive_repository.dart';
import '../../features/executive/data/repositories/executive_repository_impl.dart';
import '../../features/executive/presentation/bloc/executive_cubit.dart';
import '../bloc/session_cubit.dart';
import '../utils/crash_reporter.dart';

final getIt = GetIt.instance;

Future<void> initDI() async {
  // Utils
  getIt.registerLazySingleton<CrashReporter>(() => ConsoleCrashReporter());

  // Core
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerLazySingleton<SharedPreferences>(() => sharedPreferences);
  getIt.registerLazySingleton(() => SessionCubit());
  getIt.registerLazySingleton(() => ThemeCubit());

  // Data Sources (Singletons for state sync)
  getIt.registerLazySingleton(() => FakeAttendanceDataSource());
  getIt.registerLazySingleton(() => FakeHomeDataSource());
  getIt.registerLazySingleton(() => FakeLeaveDataSource());
  getIt.registerLazySingleton(() => FakeKpiDataSource());
  getIt.registerLazySingleton(() => FakeAppraisalDataSource());
  getIt.registerLazySingleton(() => FakePayrollDataSource());
  getIt.registerLazySingleton(() => FakeTrainingDataSource());
  getIt.registerLazySingleton(() => FakeCommunicationDataSource());
  getIt.registerLazySingleton(() => FakeItRequestDataSource());

  // Repositories
  getIt.registerLazySingleton<AttendanceRepository>(
      () => AttendanceRepositoryImpl(getIt<FakeAttendanceDataSource>()));
  getIt.registerLazySingleton<HomeRepository>(
      () => HomeRepositoryImpl(getIt<FakeHomeDataSource>()));
  getIt.registerLazySingleton<LeaveRepository>(
      () => LeaveRepositoryImpl(getIt<FakeLeaveDataSource>()));
  getIt.registerLazySingleton<KpiRepository>(
      () => KpiRepositoryImpl(getIt<FakeKpiDataSource>()));
  getIt.registerLazySingleton<AppraisalRepository>(
      () => AppraisalRepositoryImpl(getIt<FakeAppraisalDataSource>()));
  getIt.registerLazySingleton<PayrollRepository>(
      () => PayrollRepositoryImpl(getIt<FakePayrollDataSource>()));
  getIt.registerLazySingleton<TrainingRepository>(
      () => TrainingRepositoryImpl(getIt<FakeTrainingDataSource>()));
  getIt.registerLazySingleton<CommunicationRepository>(
      () => CommunicationRepositoryImpl(getIt<FakeCommunicationDataSource>()));
  getIt.registerLazySingleton<ItRequestRepository>(
      () => ItRequestRepositoryImpl(getIt<FakeItRequestDataSource>()));

  // Cubits
  getIt.registerFactory(() => AttendanceCubit(getIt<AttendanceRepository>(), getIt<LeaveRepository>()));
  getIt.registerFactory(() => HomeCubit(
      getIt<HomeRepository>(), getIt<AttendanceRepository>(), getIt<LeaveRepository>(), getIt<KpiRepository>(), getIt<TrainingRepository>()));
  getIt.registerFactory(() => LeaveCubit(getIt<LeaveRepository>()));
  getIt.registerFactory(() => KpiCubit(getIt<KpiRepository>()));
  getIt.registerFactory(() => AppraisalCubit(getIt<AppraisalRepository>(), getIt<KpiRepository>()));
  getIt.registerFactory(() => PayrollCubit(getIt<PayrollRepository>()));
  getIt.registerFactory(() => TrainingCubit(getIt<TrainingRepository>()));
  getIt.registerFactory(() => CommunicationCubit(getIt<CommunicationRepository>(), getIt<ItRequestRepository>()));
  getIt.registerFactory(() => TeamApprovalsCubit(getIt<LeaveRepository>()));
  getIt.registerFactory(() => TeamKpiCubit(getIt<KpiRepository>()));

  // Phase 10: HR Admin
  getIt.registerLazySingleton(() => FakeAdminPayrollDataSource());
  getIt.registerLazySingleton<AdminPayrollRepository>(() => AdminPayrollRepositoryImpl(getIt<FakeAdminPayrollDataSource>()));
  getIt.registerFactory(() => AdminPayrollCubit(getIt<AdminPayrollRepository>()));

  getIt.registerLazySingleton(() => FakeRecruitmentDataSource());
  getIt.registerLazySingleton<RecruitmentRepository>(() => RecruitmentRepositoryImpl(getIt<FakeRecruitmentDataSource>()));
  getIt.registerFactory(() => RecruitmentCubit(getIt<RecruitmentRepository>()));

  getIt.registerLazySingleton(() => FakeSystemConfigDataSource());
  getIt.registerLazySingleton<SystemConfigRepository>(() => SystemConfigRepositoryImpl(getIt<FakeSystemConfigDataSource>()));
  getIt.registerFactory(() => SystemConfigCubit(getIt<SystemConfigRepository>(), getIt<AppraisalRepository>()));

  getIt.registerLazySingleton(() => FakeOffboardingDataSource());
  getIt.registerLazySingleton<OffboardingRepository>(() => OffboardingRepositoryImpl(getIt<FakeOffboardingDataSource>()));
  getIt.registerFactory(() => OffboardingCubit(getIt<OffboardingRepository>()));

  // Phase 11: Executive
  getIt.registerLazySingleton(() => FakeExecutiveDataSource());
  getIt.registerLazySingleton<ExecutiveRepository>(() => ExecutiveRepositoryImpl(
        getIt<FakeExecutiveDataSource>(),
        getIt<RecruitmentRepository>(),
        getIt<AdminPayrollRepository>(),
        getIt<EngagementRepository>(),
      ));
  getIt.registerFactory(() => ExecutiveCubit(getIt<ExecutiveRepository>()));

  // Phase 14: Engagement
  getIt.registerLazySingleton(() => FakeEngagementDataSource());
  getIt.registerLazySingleton<EngagementRepository>(() => EngagementRepositoryImpl(getIt<FakeEngagementDataSource>()));
  getIt.registerFactory(() => EngagementCubit(getIt<EngagementRepository>()));

  // Phase 14: Org Chart
  getIt.registerLazySingleton(() => FakeOrgChartDataSource());
  getIt.registerLazySingleton<OrgChartRepository>(() => OrgChartRepositoryImpl(getIt<FakeOrgChartDataSource>()));
  getIt.registerFactory(() => OrgChartCubit(getIt<OrgChartRepository>()));
}
