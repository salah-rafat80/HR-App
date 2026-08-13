import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/theme_cubit.dart';

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
import '../services/token_service.dart';
import '../bloc/session_cubit.dart';
import '../utils/crash_reporter.dart';

final getIt = GetIt.instance;

Future<void> initDI() async {
  // Utils
  getIt.registerLazySingleton<CrashReporter>(() => ConsoleCrashReporter());

  // Core
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerLazySingleton<SharedPreferences>(() => sharedPreferences);
  getIt.registerLazySingleton<TokenService>(() => TokenService());
  getIt.registerLazySingleton(() => SessionCubit());
  getIt.registerLazySingleton(() => ThemeCubit());

  // API Client Setup
  /// API Base URL Configuration via --dart-define
  /// Development Examples:
  /// - Android emulator local backend: --dart-define=API_BASE_URL=http://10.0.2.2:3000
  /// - Local LAN / real device: --dart-define=API_BASE_URL=http://192.168.1.50:3000
  /// - Render production backend: --dart-define=API_BASE_URL=https://hr-app-lswi.onrender.com
  const String defaultBaseUrl = 'https://hr-app-lswi.onrender.com';
  const String baseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: defaultBaseUrl);

  final dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 10),
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      if (!options.path.contains('/auth/login')) {
        final tokenService = getIt<TokenService>();
        final token = await tokenService.getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
      }
      return handler.next(options);
    },
    onError: (DioException error, handler) async {
      if (error.response?.statusCode == 401 &&
          !error.requestOptions.path.contains('/auth/login')) {
        final tokenService = getIt<TokenService>();
        await tokenService.clearToken();
        getIt<SessionCubit>().setAuthenticated(false);
      }
      return handler.next(error);
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
  getIt.registerLazySingleton(() => FakeCommunicationDataSource());
  getIt.registerLazySingleton(() => FakeItRequestDataSource());
  getIt.registerLazySingleton(() => FakeSystemConfigDataSource());
  getIt.registerLazySingleton(() => ApiSystemConfigDataSource(dio: getIt<Dio>()));

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
  getIt.registerLazySingleton<TrainingRepository>(
      () => TrainingRepositoryImpl(getIt<FakeTrainingDataSource>()));
  getIt.registerLazySingleton<CommunicationRepository>(
      () => CommunicationRepositoryImpl(getIt<FakeCommunicationDataSource>()));
  getIt.registerLazySingleton<ItRequestRepository>(
      () => ItRequestRepositoryImpl(getIt<FakeItRequestDataSource>()));
  getIt.registerLazySingleton<SystemConfigRepository>(
      () => SystemConfigRepositoryImpl(getIt<FakeSystemConfigDataSource>(), getIt<ApiSystemConfigDataSource>()));

  // Cubits
  getIt.registerFactory(() => AttendanceCubit(getIt<AttendanceRepository>(), getIt<io.Socket>(), getIt<SystemConfigRepository>()));
  getIt.registerFactory(() => HomeCubit(
      getIt<HomeRepository>(), getIt<AttendanceRepository>(), getIt<LeaveRepository>(), getIt<KpiRepository>(), getIt<TrainingRepository>()));
  getIt.registerFactory(() => LeaveCubit(getIt<LeaveRepository>(), getIt<io.Socket>()));
  getIt.registerFactory(() => KpiCubit(getIt<KpiRepository>(), getIt<io.Socket>()));
  getIt.registerFactory(() => AppraisalCubit(getIt<AppraisalRepository>(), getIt<KpiRepository>(), getIt<io.Socket>()));
  getIt.registerFactory(() => PayrollCubit(getIt<PayrollRepository>(), getIt<io.Socket>()));
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
