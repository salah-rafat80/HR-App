class Announcement {
  final String id;
  final String title;
  final String content;
  final DateTime date;

  const Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
  });
}

class Colleague {
  final String id;
  final String name;
  final String department;
  final String avatarUrl;

  const Colleague({
    required this.id,
    required this.name,
    required this.department,
    required this.avatarUrl,
  });
}

class Holiday {
  final String name;
  final DateTime date;

  const Holiday({
    required this.name,
    required this.date,
  });
}

class HomeDashboardData {
  final String employeeName;
  final DateTime todayDate;
  final int leaveDaysLeft;
  final int leaveDaysTotal;
  final double kpiScorePercent;
  final List<Announcement> announcements;
  final List<Colleague> birthdaysToday;
  final List<Holiday> upcomingHolidays;
  final int pendingMandatoryTrainingCount;

  const HomeDashboardData({
    required this.employeeName,
    required this.todayDate,
    required this.leaveDaysLeft,
    required this.leaveDaysTotal,
    required this.kpiScorePercent,
    required this.announcements,
    required this.birthdaysToday,
    required this.upcomingHolidays,
    this.pendingMandatoryTrainingCount = 0,
  });
}
