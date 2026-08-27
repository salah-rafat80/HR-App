import 'package:hr_core/features/communication/domain/entities/communication_entities.dart';
import 'package:hr_core/features/communication/domain/repositories/announcement_repository.dart';
import 'package:hr_core/features/communication/data/datasources/announcement_datasource.dart';

class AnnouncementRepositoryImpl implements AnnouncementRepository {
  final AnnouncementDataSource dataSource;

  AnnouncementRepositoryImpl({required this.dataSource});

  @override
  Future<List<Announcement>> getAnnouncements() {
    return dataSource.getAnnouncements();
  }

  @override
  Future<Announcement> createAnnouncement(String title, String body, {String? department}) {
    return dataSource.addAnnouncement(title, body, department: department);
  }
}
