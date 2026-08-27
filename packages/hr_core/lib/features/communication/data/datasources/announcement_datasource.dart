import 'package:hr_core/features/communication/domain/entities/communication_entities.dart';

abstract class AnnouncementDataSource {
  Future<List<Announcement>> getAnnouncements();
  Future<Announcement> addAnnouncement(String title, String body, {String? department});
}
