import 'package:hr_core/core/network/auth_interceptor.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/theme_cubit.dart';
import '../services/biometric_service.dart';
import '../services/location_service.dart';

import 'package:hr_core/features/attendance/data/datasources/api_attendance_repository_impl.dart';
import 'package:hr_core/features/attendance/domain/repositories/attendance_repository.dart';
import '../../features/attendance/presentation/bloc/attendance_cubit.dart';
import 'package:hr_core/features/leave/data/datasources/api_leave_repository_impl.dart';
import 'package:hr_core/features/leave/domain/repositories/leave_repository.dart';
import '../../features/leave/presentation/bloc/leave_cubit.dart';
import 'package:dio/dio.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import 'package:hr_core/features/kpi/data/datasources/api_kpi_repository_impl.dart';
import 'package:hr_core/features/kpi/domain/repositories/kpi_repository.dart';
import '../../features/kpi/presentation/bloc/kpi_cubit.dart';
import 'package:hr_core/features/appraisal/data/datasources/api_appraisal_repository_impl.dart';
import 'package:hr_core/features/appraisal/domain/repositories/appraisal_repository.dart';
import '../../features/appraisal/presentation/bloc/appraisal_cubit.dart';
import 'package:hr_core/features/payroll/data/datasources/api_payroll_repository_impl.dart';
import 'package:hr_core/features/payroll/domain/repositories/payroll_repository.dart';
import '../../features/payroll/presentation/bloc/payroll_cubit.dart';
import 'package:hr_core/features/training/data/datasources/fake_training_datasource.dart';
import 'package:hr_core/features/training/data/repositories/training_repository_impl.dart';
import 'package:hr_core/features/training/domain/repositories/training_repository.dart';
import '../../features/training/presentation/bloc/training_cubit.dart';
import 'package:hr_core/features/communication/domain/repositories/announcement_repository.dart';
import 'package:hr_core/features/communication/data/datasources/announcement_datasource.dart';
import 'package:hr_core/features/communication/data/datasources/api_announcement_datasource.dart';
import 'package:hr_core/features/communication/data/repositories/announcement_repository_impl.dart';
import 'package:hr_core/features/communication/data/datasources/communication_datasource.dart';
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
import 'package:hr_core/features/admin/data/datasources/fake_system_config_datasource.dart';
import 'package:hr_core/features/admin/data/datasources/api_system_config_datasource.dart';
import 'package:hr_core/features/admin/domain/repositories/system_config_repository.dart';
import 'package:hr_core/features/admin/data/repositories/system_config_repository_impl.dart';
import 'package:hr_core/core/services/token_storage.dart';
import '../services/token_service.dart';
import '../bloc/session_cubit.dart';
import '../utils/crash_reporter.dart';

final getIt = GetIt.instance;

Future<void> initDI({String? overrideBaseUrl}) async {
  // Utils
  getIt.registerLazySingleton<CrashReporter>(() => ConsoleCrashReporter());

  // Core
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerLazySingleton<SharedPreferences>(() => sharedPreferences);
  getIt.registerLazySingleton<TokenStorage>(() => SecureTokenStorage());
  getIt.registerLazySingleton<TokenService>(
      () => TokenService(storage: getIt<TokenStorage>()));
  getIt.registerLazySingleton(() => SessionCubit());
  getIt.registerLazySingleton(() => ThemeCubit());

  // API Client Setup
  final String rawEnv = const String.fromEnvironment('API_BASE_URL');
  final String baseUrl = (overrideBaseUrl ?? rawEnv).trim();
  if (baseUrl.isEmpty) {
    throw StateError(
      'CRITICAL CONFIGURATION ERROR: API_BASE_URL is missing or blank.\n'
      'You must supply --dart-define=API_BASE_URL=<url> when running the application.\n'
      'Examples:\n'
      '  - Android Emulator: --dart-define=API_BASE_URL=http://10.0.2.2:3000\n'
      '  - Physical LAN Device: --dart-define=API_BASE_URL=http://192.168.1.50:3000\n'
      '  - Production Server: --dart-define=API_BASE_URL=https://api.yourdomain.com',
    );
  }

  final dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  dio.interceptors.add(SingleFlightAuthInterceptor(
    dio: dio,
    tokenStorage: getIt<TokenStorage>(),
    onUnauthenticated: () async {
      getIt<SessionCubit>().setAuthenticated(false);
    },
  ));

  getIt.registerLazySingleton<Dio>(() => dio);

  final socket = io.io(
    baseUrl,
    io.OptionBuilder()
        .setTransports(['websocket', 'polling'])
        .disableAutoConnect()
        .disableReconnection()
        .build(),
  );
  socket.onConnectError((_) {});
  socket.onError((_) {});
  getIt.registerLazySingleton<io.Socket>(() => socket);


  // Data Sources (Singletons for state sync)
  getIt.registerLazySingleton(() => FakeHomeDataSource());
  getIt.registerLazySingleton(() => FakeTrainingDataSource());
  getIt.registerLazySingleton(() => FakeItRequestDataSource());
  getIt.registerLazySingleton(() => FakeSystemConfigDataSource());
  getIt.registerLazySingleton(() => ApiSystemConfigDataSource(dio: getIt<Dio>()));

  getIt.registerLazySingleton<BiometricService>(() => BiometricServiceImpl());
  getIt.registerLazySingleton<LocationService>(() => LocationServiceImpl());

  // Repositories
  getIt.registerLazySingleton<AttendanceRepository>(
      () => ApiAttendanceRepositoryImpl(dio: getIt<Dio>()));
  getIt.registerLazySingleton<HomeRepository>(
      () => HomeRepositoryImpl(getIt<FakeHomeDataSource>()));
  getIt.registerLazySingleton<LeaveRepository>(
      () => ApiLeaveRepositoryImpl(dio: getIt<Dio>()));
  getIt.registerLazySingleton<KpiRepository>(
      () => ApiKpiRepositoryImpl(dio: getIt<Dio>()));
  getIt.registerLazySingleton<AppraisalRepository>(
      () => ApiAppraisalRepositoryImpl(dio: getIt<Dio>()));
  getIt.registerLazySingleton<PayrollRepository>(
      () => ApiPayrollRepositoryImpl(dio: getIt<Dio>()));

  // Announcements
  getIt.registerLazySingleton<AnnouncementDataSource>(
    () => ApiAnnouncementDataSource(dio: getIt<Dio>()),
  );

  getIt.registerLazySingleton<AnnouncementRepository>(
    () => AnnouncementRepositoryImpl(dataSource: getIt<AnnouncementDataSource>()),
  );

  getIt.registerLazySingleton<CommunicationDataSource>(
    () => FakeCommunicationDataSource(),
  );

  getIt.registerLazySingleton<CommunicationRepository>(
    () => CommunicationRepositoryImpl(getIt<CommunicationDataSource>()),
  );

  getIt.registerLazySingleton<ItRequestRepository>(
      () => ItRequestRepositoryImpl(getIt<FakeItRequestDataSource>()));
  getIt.registerLazySingleton<SystemConfigRepository>(
      () => SystemConfigRepositoryImpl(getIt<FakeSystemConfigDataSource>(), getIt<ApiSystemConfigDataSource>()));
  getIt.registerLazySingleton<TrainingRepository>(
      () => TrainingRepositoryImpl(getIt<FakeTrainingDataSource>()));

  // Cubits
  getIt.registerLazySingleton(() => AttendanceCubit(getIt<AttendanceRepository>(), getIt<io.Socket>()));
  getIt.registerLazySingleton(() => HomeCubit(
      getIt<HomeRepository>(), getIt<AttendanceRepository>(), getIt<LeaveRepository>(), getIt<KpiRepository>(), getIt<TrainingRepository>()));
  getIt.registerLazySingleton(() => LeaveCubit(getIt<LeaveRepository>(), getIt<io.Socket>()));
  getIt.registerLazySingleton(() => KpiCubit(getIt<KpiRepository>(), getIt<io.Socket>()));
  getIt.registerFactory(() => AppraisalCubit(getIt<AppraisalRepository>(), getIt<KpiRepository>(), getIt<io.Socket>()));
  getIt.registerFactory(() => PayrollCubit(getIt<PayrollRepository>(), getIt<io.Socket>()));
  getIt.registerFactory(() => TrainingCubit(getIt<TrainingRepository>()));
  getIt.registerFactory(() => CommunicationCubit(getIt<CommunicationRepository>(), getIt<AnnouncementRepository>(), getIt<ItRequestRepository>()));


  // Phase 14: Engagement
  getIt.registerLazySingleton(() => FakeEngagementDataSource());
  getIt.registerLazySingleton<EngagementRepository>(() => EngagementRepositoryImpl(getIt<FakeEngagementDataSource>()));
  getIt.registerFactory(() => EngagementCubit(getIt<EngagementRepository>()));

  // Phase 14: Org Chart
  getIt.registerLazySingleton(() => FakeOrgChartDataSource());
  getIt.registerLazySingleton<OrgChartRepository>(() => OrgChartRepositoryImpl(getIt<FakeOrgChartDataSource>()));
  getIt.registerFactory(() => OrgChartCubit(getIt<OrgChartRepository>()));
}
