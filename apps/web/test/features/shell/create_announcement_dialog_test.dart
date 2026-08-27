import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hr_core/core/enums/role_enums.dart';
import 'package:hr_core/features/communication/domain/entities/communication_entities.dart';
import 'package:hr_core/features/communication/domain/errors/announcement_exception.dart';
import 'package:hr_core/features/communication/domain/repositories/announcement_repository.dart';
import 'package:hr_core/features/leave/domain/entities/leave_balance.dart';
import 'package:hr_core/features/leave/domain/entities/leave_request.dart';
import 'package:hr_core/features/leave/domain/repositories/leave_repository.dart';
import 'package:hr_web/features/shell/presentation/pages/dashboard_screen.dart';
import 'package:get_it/get_it.dart';
import 'package:hr_web/core/bloc/session_cubit.dart';

class MockSessionCubit extends Fake implements SessionCubit {
  @override
  WebSessionState get state => const WebSessionState(status: WebSessionStatus.authenticated, role: UserRole.hrAdmin);
  @override
  Stream<WebSessionState> get stream => const Stream.empty();
}

class MockLeaveRepository extends Fake implements LeaveRepository {
  @override Future<List<LeaveBalance>> getBalances() async => [];
  @override Future<List<LeaveRequest>> getMyRequests({dynamic status}) async => [];
  @override Future<List<LeaveRequest>> getPendingApprovals(ApprovalScope scope) async => [];
}

class MockAnnouncementRepository extends Fake implements AnnouncementRepository {
  @override Future<List<Announcement>> getAnnouncements({int limit = 10, int offset = 0, String? department}) async => [];
  @override Future<Announcement> createAnnouncement(String title, String content, {String? department}) async {
    throw AnnouncementException('network_error', 'error_communication_failed');
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    EasyLocalization.logger.enableBuildModes = [];
    await EasyLocalization.ensureInitialized();
    final getIt = GetIt.instance;
    getIt.registerSingleton<LeaveRepository>(MockLeaveRepository());
    getIt.registerSingleton<AnnouncementRepository>(MockAnnouncementRepository());
  });

  tearDownAll(() {
    GetIt.instance.reset();
  });

  testWidgets('Web create-announcement dialog shows safe localized error on failure', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    
    final sessionCubit = MockSessionCubit();

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('ar')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        startLocale: const Locale('en'),
        child: Builder(
          builder: (context) {
            return MaterialApp(
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              locale: context.locale,
              home: Scaffold(
                body: BlocProvider<SessionCubit>.value(
                  value: sessionCubit,
                  child: const DashboardScreen(),
                ),
              ),
            );
          }
        ),
      ),
    );

    // wait for cubit and localization to load
    await tester.pumpAndSettle();

    // Find the create announcement button (by icon or text)
    final createButton = find.text('إضافة إعلان جديد');
    expect(createButton, findsWidgets);
    await tester.tap(createButton.first);
    
    // open modal
    await tester.pumpAndSettle();

    // enter title/body
    await tester.enterText(find.byType(TextFormField).first, 'Test Title');
    await tester.enterText(find.byType(TextFormField).last, 'Test Body');
    
    // submit button in dialog
    final submitButton = find.text('نشر الإعلان');
    expect(submitButton, findsWidgets);
    await tester.tap(submitButton.first);
    
    // wait for async
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // wait for snackbar
    
    // Assert dialog remains mounted
    expect(find.byType(AlertDialog), findsOneWidget);
    
    // Assert fields retain values
    expect(find.text('Test Title'), findsOneWidget);
    expect(find.text('Test Body'), findsOneWidget);
    
    // Assert inline submit loader is no longer active (no AppLoader)
    expect(find.byType(CircularProgressIndicator), findsNothing);
    
    // Assert safe localized error appears exactly
    expect(find.text('Failed to communicate with the server.'), findsOneWidget);
    
    // Assert raw key is not rendered
    expect(find.text('error_communication_failed'), findsNothing);
    
    // Assert success message does not appear
    expect(find.text('Announcement published successfully'), findsNothing);
    expect(find.text('تم نشر الإعلان بنجاح'), findsNothing);
    
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}
