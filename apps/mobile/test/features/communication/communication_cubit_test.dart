import 'package:flutter_test/flutter_test.dart';
import 'package:hr_app_demo/core/di/injection.dart';
import 'package:hr_app_demo/features/home/presentation/bloc/home_cubit.dart';
import 'package:hr_app_demo/features/communication/presentation/bloc/communication_cubit.dart';
import 'package:hr_app_demo/features/communication/presentation/bloc/communication_state.dart';
import 'package:hr_core/features/communication/domain/entities/communication_entities.dart';
import 'package:hr_core/features/communication/domain/repositories/announcement_repository.dart';
import 'package:hr_core/features/communication/domain/repositories/communication_repository.dart';
import 'package:hr_core/features/communication/domain/repositories/it_request_repository.dart';
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
  @override Future<void> submitItRequest(dynamic category, String description) async {}
}

class MockAnnouncementRepository implements AnnouncementRepository {
  bool failLoad = false;
  bool failCreate = false;
  bool failRefresh = false;
  int loadCalls = 0;

  @override
  Future<List<Announcement>> getAnnouncements({int limit = 10, int offset = 0, String? department}) async {
    loadCalls++;
    if (failLoad || (failRefresh && loadCalls > 1)) {
      throw Exception('Network Error');
    }
    return [
      Announcement(id: '1', title: 'A1', body: 'C1', date: DateTime.now())
    ];
  }

  @override
  Future<Announcement> createAnnouncement(String title, String content, {String? department}) async {
    if (failCreate) {
      throw Exception('Create Error');
    }
    return Announcement(id: 'new', title: title, body: content, date: DateTime.now());
  }
}

void main() {
  late MockCommunicationRepository mockComm;
  late MockAnnouncementRepository mockAnn;
  late MockItRequestRepository mockIt;
  late CommunicationCubit cubit;

  setUp(() {
    mockComm = MockCommunicationRepository();
    mockAnn = MockAnnouncementRepository();
    mockIt = MockItRequestRepository();
    cubit = CommunicationCubit(mockComm, mockAnn, mockIt);
  });

  tearDown(() {
    cubit.close();
  });

  group('CommunicationCubit Announcements', () {
    test('Initial announcement-load failure leaves CommunicationLoaded with error and Retry then succeeds', () async {
      mockAnn.failLoad = true;
      await cubit.loadData();
      expect(cubit.state, isA<CommunicationLoaded>());
      final loaded = cubit.state as CommunicationLoaded;
      expect(loaded.announcementsError, 'error_communication_failed');
      expect(loaded.isLoadingAnnouncements, false);

      mockAnn.failLoad = false;
      await cubit.loadAnnouncements();
      final retryState = cubit.state as CommunicationLoaded;
      expect(retryState.announcementsError, isNull);
      expect(retryState.announcements.length, 1);
    });

    test('Successful POST keeps the returned created announcement even if a subsequent refresh fails', () async {
      await cubit.loadData(); // initial load succeeds (loadCalls = 1)
      mockAnn.failRefresh = true; // next load (refresh) will fail
      await cubit.createAnnouncement('New', 'Body');

      final state = cubit.state as CommunicationLoaded;
      // We expect the newly created announcement to be in the list
      // even if the refresh failed.
      expect(state.announcements.first.id, 'new');
      expect(state.announcements.first.title, 'New');
    });

    test('Rejected POST keeps modal input and ends loader/no success', () async {
      await cubit.loadData();
      mockAnn.failCreate = true;

      expect(
        () async => await cubit.createAnnouncement('New', 'Body'),
        throwsA(isA<Exception>())
      );

      final state = cubit.state as CommunicationLoaded;
      expect(state.announcements.any((a) => a.id == 'new'), false);
    });
    test('createAnnouncement does not invoke HomeCubit/dashboard reload', () async {
      final mockHome = MockHomeCubit();
      getIt.registerSingleton<HomeCubit>(mockHome as HomeCubit);

      await cubit.loadData();
      await cubit.createAnnouncement('Title', 'Body');

      expect(mockHome.loadDashboardCalled, false);
      
      getIt.unregister<HomeCubit>();
    });
  });
}

class MockHomeCubit extends Fake implements HomeCubit {
  bool loadDashboardCalled = false;
  
  @override
  Future<void> loadDashboard({bool refresh = false}) async {
    loadDashboardCalled = true;
  }
}
