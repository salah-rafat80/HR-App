import 'package:hr_core/features/communication/domain/entities/communication_entities.dart';

abstract class AnnouncementRepository {
  Future<List<Announcement>> getAnnouncements();
  Future<Announcement> createAnnouncement(String title, String body, {String? department});
}
