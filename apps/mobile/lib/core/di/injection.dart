import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/theme_cubit.dart';

import 'package:hr_core/features/attendance/data/datasources/fake_attendance_datasource.dart';
import 'package:hr_core/features/attendance/data/repositories/attendance_repository_impl.dart';
import 'package:hr_core/features/attendance/domain/repositories/attendance_repository.dart';
import '../../features/attendance/presentation/bloc/attendance_cubit.dart';
import 'package:hr_core/features/leave/data/datasources/fake_leave_datasource.dart';
import 'package:hr_core/features/leave/data/repositories/leave_repository_impl.dart';
import 'package:hr_core/features/leave/domain/repositories/leave_repository.dart';
import '../../features/leave/presentation/bloc/leave_cubit.dart';
import 'package:hr_core/features/kpi/data/datasources/fake_kpi_datasource.dart';
import 'package:hr_core/features/kpi/data/repositories/kpi_repository_impl.dart';
import 'package:hr_core/features/kpi/domain/repositories/kpi_repository.dart';
import '../../features/kpi/presentation/bloc/kpi_cubit.dart';
import 'package:hr_core/features/appraisal/data/datasources/fake_appraisal_datasource.dart';
import 'package:hr_core/features/appraisal/data/repositories/appraisal_repository_impl.dart';
import 'package:hr_core/features/appraisal/domain/repositories/appraisal_repository.dart';
import '../../features/appraisal/presentation/bloc/appraisal_cubit.dart';
import 'package:hr_core/features/payroll/data/datasources/fake_payroll_datasource.dart';
import 'package:hr_core/features/payroll/data/repositories/payroll_repository_impl.dart';
import 'package:hr_core/features/payroll/domain/repositories/payroll_repository.dart';
import '../../features/payroll/presentation/bloc/payroll_cubit.dart';
import 'package:hr_core/features/training/data/datasources/fake_training_datasource.dart';
import 'package:hr_core/features/training/data/repositories/training_repository_impl.dart';
import 'package:hr_core/features/training/domain/repositories/training_repository.dart';
import '../../features/training/presentation/bloc/training_cubit.dart';
import 'package:hr_core/features/communication/data/datasources/fake_communication_datasource.dart';
import 'package:hr_core/features/communication/data/datasources/fake_it_request_datasource.dart';
import 'package:hr_core/features/communication/data/repositories/communication_repository_impl.dart';
import 'package:hr_core/features/communication/data/repositories/it_request_repository_impl.dart';
import 'package:hr_core/features/communication/domain/repositories/communication_repository.dart';
import 'package:hr_core/features/communication/domain/repositories/it_request_repository.dart';
import '../../features/communication/presentation/bloc/communication_cubit.dart';
import 'package:hr_core/features/home/data/datasources/fake_home_datasource.dart';
import 'package:hr_core/features/home/data/repositories/home_repository_impl.dart';
import 'package:hr_core/features/home/domain/repositories/home_repository.dart';
import '../../features/home/presentation/bloc/home_cubit.dart';
import 'package:hr_core/features/engagement/data/datasources/fake_engagement_datasource.dart';
import 'package:hr_core/features/engagement/domain/repositories/engagement_repository.dart';
import 'package:hr_core/features/engagement/data/repositories/engagement_repository_impl.dart';
import '../../features/engagement/presentation/bloc/engagement_cubit.dart';
import 'package:hr_core/features/org_chart/data/datasources/fake_org_chart_datasource.dart';
import 'package:hr_core/features/org_chart/domain/repositories/org_chart_repository.dart';
import 'package:hr_core/features/org_chart/data/repositories/org_chart_repository_impl.dart';
import '../../features/org_chart/presentation/bloc/org_chart_cubit.dart';
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


  // Phase 14: Engagement
  getIt.registerLazySingleton(() => FakeEngagementDataSource());
  getIt.registerLazySingleton<EngagementRepository>(() => EngagementRepositoryImpl(getIt<FakeEngagementDataSource>()));
  getIt.registerFactory(() => EngagementCubit(getIt<EngagementRepository>()));

  // Phase 14: Org Chart
  getIt.registerLazySingleton(() => FakeOrgChartDataSource());
  getIt.registerLazySingleton<OrgChartRepository>(() => OrgChartRepositoryImpl(getIt<FakeOrgChartDataSource>()));
  getIt.registerFactory(() => OrgChartCubit(getIt<OrgChartRepository>()));
}
