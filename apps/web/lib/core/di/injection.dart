import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/theme_cubit.dart';

// Import Data Sources from hr_core
import 'package:dio/dio.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:hr_core/features/leave/data/datasources/api_leave_repository_impl.dart';
import 'package:hr_core/features/attendance/data/datasources/api_attendance_repository_impl.dart';
import 'package:hr_core/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:hr_core/features/kpi/data/datasources/api_kpi_repository_impl.dart';
import 'package:hr_core/features/appraisal/data/datasources/api_appraisal_repository_impl.dart';
import 'package:hr_core/features/appraisal/domain/repositories/appraisal_repository.dart';
import 'package:hr_core/features/leave/domain/repositories/leave_repository.dart';
import 'package:hr_core/features/kpi/domain/repositories/kpi_repository.dart';
import 'package:hr_core/features/admin/data/datasources/fake_admin_payroll_datasource.dart';
import 'package:hr_core/features/admin/data/datasources/fake_recruitment_datasource.dart';
import 'package:hr_core/features/admin/data/datasources/fake_system_config_datasource.dart';
import 'package:hr_core/features/admin/data/datasources/api_system_config_datasource.dart';
import 'package:hr_core/features/admin/data/datasources/fake_offboarding_datasource.dart';
import 'package:hr_core/features/executive/data/datasources/fake_executive_datasource.dart';
import 'package:hr_core/features/engagement/data/datasources/fake_engagement_datasource.dart';
import 'package:hr_core/features/admin/data/repositories/admin_payroll_repository_impl.dart';
import 'package:hr_core/features/admin/domain/repositories/admin_payroll_repository.dart';
import 'package:hr_core/features/admin/data/repositories/recruitment_repository_impl.dart';
import 'package:hr_core/features/admin/domain/repositories/recruitment_repository.dart';
import 'package:hr_core/features/admin/data/repositories/system_config_repository_impl.dart';
import 'package:hr_core/features/admin/domain/repositories/system_config_repository.dart';
import 'package:hr_core/features/admin/data/repositories/offboarding_repository_impl.dart';
import 'package:hr_core/features/admin/domain/repositories/offboarding_repository.dart';
import 'package:hr_core/features/executive/data/repositories/executive_repository_impl.dart';
import 'package:hr_core/features/executive/domain/repositories/executive_repository.dart';
import 'package:hr_core/features/engagement/data/repositories/engagement_repository_impl.dart';
import 'package:hr_core/features/engagement/domain/repositories/engagement_repository.dart';

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

  // API Client Setup
  final String baseUrl = 'http://localhost:3000';
  
  final dio = Dio(BaseOptions(baseUrl: baseUrl));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final prefs = getIt<SharedPreferences>();
      final token = prefs.getString('jwt_token');
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      return handler.next(options);
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


  // Data Sources (Singletons for state sync within web app)
  getIt.registerLazySingleton(() => FakeAdminPayrollDataSource());
  getIt.registerLazySingleton(() => FakeRecruitmentDataSource());
  getIt.registerLazySingleton(() => FakeSystemConfigDataSource());
  getIt.registerLazySingleton(() => ApiSystemConfigDataSource(dio: getIt<Dio>()));
  getIt.registerLazySingleton(() => FakeOffboardingDataSource());
  getIt.registerLazySingleton(() => FakeExecutiveDataSource());
  getIt.registerLazySingleton(() => FakeEngagementDataSource());

  // Repositories
  getIt.registerLazySingleton<LeaveRepository>(() => ApiLeaveRepositoryImpl(dio: getIt<Dio>()));
  getIt.registerLazySingleton<AttendanceRepository>(() => ApiAttendanceRepositoryImpl(dio: getIt<Dio>()));
  getIt.registerLazySingleton<KpiRepository>(() => ApiKpiRepositoryImpl(dio: getIt<Dio>()));
  getIt.registerLazySingleton<AppraisalRepository>(() => ApiAppraisalRepositoryImpl(dio: getIt<Dio>()));
  getIt.registerLazySingleton<AdminPayrollRepository>(() => AdminPayrollRepositoryImpl(getIt<FakeAdminPayrollDataSource>()));
  getIt.registerLazySingleton<RecruitmentRepository>(() => RecruitmentRepositoryImpl(getIt<FakeRecruitmentDataSource>()));
  getIt.registerLazySingleton<SystemConfigRepository>(() => SystemConfigRepositoryImpl(getIt<FakeSystemConfigDataSource>(), getIt<ApiSystemConfigDataSource>()));
  getIt.registerLazySingleton<OffboardingRepository>(() => OffboardingRepositoryImpl(getIt<FakeOffboardingDataSource>()));
  getIt.registerLazySingleton<EngagementRepository>(() => EngagementRepositoryImpl(getIt<FakeEngagementDataSource>()));
  
  // Executive Repo requires multiple data sources
  getIt.registerLazySingleton<ExecutiveRepository>(() => ExecutiveRepositoryImpl(
        getIt<FakeExecutiveDataSource>(),
        getIt<RecruitmentRepository>(),
        getIt<AdminPayrollRepository>(),
        getIt<EngagementRepository>(),
      ));
}
