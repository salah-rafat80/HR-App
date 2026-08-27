import 'package:flutter_test/flutter_test.dart';
import 'package:hr_core/core/enums/role_enums.dart';
import 'package:hr_core/features/communication/domain/entities/communication_entities.dart';
import 'package:hr_core/features/communication/domain/repositories/announcement_repository.dart';
import 'package:hr_core/features/leave/domain/entities/leave_balance.dart';
import 'package:hr_core/features/leave/domain/entities/leave_request.dart';
import 'package:hr_core/features/leave/domain/repositories/leave_repository.dart';
import 'package:hr_web/features/shell/presentation/bloc/dashboard_cubit.dart';

class MockLeaveRepository extends Fake implements LeaveRepository {
  @override Future<List<LeaveBalance>> getBalances() async => [];
  @override Future<List<LeaveRequest>> getMyRequests({dynamic status}) async => [];
  @override Future<List<LeaveRequest>> getPendingApprovals(ApprovalScope scope) async => [];
}

class MockAnnouncementRepository extends Fake implements AnnouncementRepository {
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
  late MockLeaveRepository mockLeave;
  late MockAnnouncementRepository mockAnn;
  late DashboardCubit cubit;

  setUp(() {
    mockLeave = MockLeaveRepository();
    mockAnn = MockAnnouncementRepository();
    cubit = DashboardCubit(mockLeave, mockAnn);
  });

  tearDown(() {
    cubit.close();
  });

  group('DashboardCubit Announcements', () {
    test('Initial announcement-load failure leaves DashboardState with error and Retry then succeeds', () async {
      mockAnn.failLoad = true;
      await cubit.loadDashboard(UserRole.employee);

      expect(cubit.state.announcementsError, 'error_communication_failed');
      expect(cubit.state.isLoading, false);

      mockAnn.failLoad = false;
      await cubit.loadAnnouncementsOnly();
      expect(cubit.state.announcementsError, isNull);
      expect(cubit.state.announcements.length, 1);
    });

    test('Successful POST keeps the returned created announcement even if a subsequent refresh fails', () async {
      await cubit.loadDashboard(UserRole.employee); // initial load succeeds (loadCalls = 1)
      mockAnn.failRefresh = true; // next load (refresh) will fail
      await cubit.createAnnouncement('New', 'Body');

      // We expect the newly created announcement to be in the list
      // even if the refresh failed.
      expect(cubit.state.announcements.first.id, 'new');
      expect(cubit.state.announcements.first.title, 'New');
    });

    test('Rejected POST keeps modal input and ends loader/no success', () async {
      await cubit.loadDashboard(UserRole.employee);
      mockAnn.failCreate = true;

      expect(
        () async => await cubit.createAnnouncement('New', 'Body'),
        throwsA(isA<Exception>())
      );

      expect(cubit.state.announcements.any((a) => a.id == 'new'), false);
    });
  });
}
