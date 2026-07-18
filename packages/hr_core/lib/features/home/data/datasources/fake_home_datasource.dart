import '../../domain/entities/home_entities.dart';

class FakeHomeDataSource {
  final HomeDashboardData _mockData = HomeDashboardData(
    employeeName: 'Ahmed Hassan',
    todayDate: DateTime.now(),
    leaveDaysLeft: 18,
    leaveDaysTotal: 24,
    kpiScorePercent: 0.85,
    announcements: [
      Announcement(
        id: '1',
        title: 'Q3 Townhall Meeting',
        content: 'Join us for the Q3 townhall meeting next week.',
        date: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Announcement(
        id: '2',
        title: 'New Office Policy',
        content: 'Please review the updated office hybrid policy.',
        date: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ],
    birthdaysToday: [
      Colleague(
        id: '101',
        name: 'Sara Ali',
        department: 'Design',
        avatarUrl: 'assets/images/avatar1.png',
      ),
    ],
    upcomingHolidays: [
      Holiday(
        name: 'Eid Al-Fitr',
        date: DateTime.now().add(const Duration(days: 20)),
      ),
    ],
  );

  Future<HomeDashboardData> getDashboardData() async {
    await Future.delayed(const Duration(milliseconds: 700));
    return _mockData;
  }
}
