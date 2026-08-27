import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hr_app_demo/features/communication/presentation/bloc/communication_cubit.dart';
import 'package:hr_app_demo/features/communication/presentation/widgets/new_announcement_modal.dart';
import 'package:hr_core/features/communication/domain/repositories/announcement_repository.dart';
import 'package:hr_core/features/communication/domain/repositories/communication_repository.dart';
import 'package:hr_core/features/communication/domain/repositories/it_request_repository.dart';
import 'package:hr_core/features/communication/domain/errors/announcement_exception.dart';
import 'package:hr_core/features/communication/domain/entities/communication_entities.dart';
import 'package:hr_core/features/communication/domain/entities/it_request_entities.dart';

class MockCommunicationRepository implements CommunicationRepository {
  @override Future<List<ChatMessage>> getChatMessages() async => [];
  @override Future<void> sendChatMessage(String text) async {}
  @override Future<List<Poll>> getPolls() async => [];
  @override Future<void> voteInPoll(String pollId, String optionId) async {}
  @override Future<List<HandbookSection>> getHandbookSections() async => [];
}

class MockItRequestRepository implements ItRequestRepository {
  @override Future<List<ItRequest>> getMyItRequests() async => [];
  @override Future<void> submitItRequest(ItRequestCategory category, String description) async {}
}

class MockAnnouncementRepository implements AnnouncementRepository {
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
  });

  testWidgets('Mobile NewAnnouncementModal shows safe localized error on failure', (tester) async {
    final mockComm = MockCommunicationRepository();
    final mockIt = MockItRequestRepository();
    final mockAnn = MockAnnouncementRepository();
    
    final cubit = CommunicationCubit(mockComm, mockAnn, mockIt);

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('ar')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        startLocale: const Locale('en'),
        child: Builder(
          builder: (context) {
            return ScreenUtilInit(
              designSize: const Size(390, 844),
              builder: (_, __) => MaterialApp(
                localizationsDelegates: context.localizationDelegates,
                supportedLocales: context.supportedLocales,
                locale: context.locale,
                home: Scaffold(
                  body: BlocProvider.value(
                    value: cubit,
                    child: const NewAnnouncementModal(),
                  ),
                ),
              ),
            );
          }
        ),
      ),
    );

    // wait for localization
    await tester.pumpAndSettle();

    // enter title/body
    await tester.enterText(find.byType(TextFormField).first, 'Test Title');
    await tester.enterText(find.byType(TextFormField).last, 'Test Body');
    
    // submit
    final submitButton = find.byIcon(Icons.send_rounded);
    expect(submitButton, findsOneWidget);
    await tester.tap(submitButton);
    
    // wait for async
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // wait for snackbar
    
    // Assert dialog remains mounted
    expect(find.byType(NewAnnouncementModal), findsOneWidget);
    
    // Assert fields retain values
    expect(find.text('Test Title'), findsOneWidget);
    expect(find.text('Test Body'), findsOneWidget);
    
    // Assert inline submit loader is no longer active
    expect(find.byType(CircularProgressIndicator), findsNothing);
    // and submit button remains enabled (we can't easily check enabled, but we check icon)
    final sendIcon = find.byIcon(Icons.send_rounded);
    expect(sendIcon, findsOneWidget);
    
    // Assert safe localized error appears exactly
    expect(find.text('Failed to communicate with the server.'), findsOneWidget);
    
    // Assert raw key is not rendered
    expect(find.text('error_communication_failed'), findsNothing);
    
    // Assert success message does not appear
    expect(find.text('Announcement published successfully'), findsNothing);
    expect(find.text('تم نشر الإعلان بنجاح'), findsNothing);
  });
}
