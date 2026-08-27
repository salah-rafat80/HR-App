import 'package:dio/dio.dart';
import 'package:hr_core/features/communication/domain/entities/communication_entities.dart';
import 'announcement_datasource.dart';
import '../../domain/errors/announcement_exception.dart';
class ApiAnnouncementDataSource implements AnnouncementDataSource {
  final Dio dio;

  ApiAnnouncementDataSource({required this.dio});

  @override
  Future<List<Announcement>> getAnnouncements() async {
    try {
      final response = await dio.get('/communication/announcements');
      if (response.data is! List) {
        throw const AnnouncementException('malformed_contract', 'error_invalid_response');
      }
      final data = response.data as List;
      return data.map((json) {
        if (json is! Map<String, dynamic>) {
          throw const AnnouncementException('malformed_contract', 'error_invalid_response');
        }
        return _parseJsonOrThrow(json);
      }).toList();
    } on DioException catch (e) {
      throw _mapDioException(e);
    } catch (e) {
      if (e is AnnouncementException) rethrow;
      throw const AnnouncementException('server_error', 'error_server');
    }
  }

  @override
  Future<Announcement> addAnnouncement(String title, String body, {String? department}) async {
    try {
      final response = await dio.post('/communication/announcements', data: {
        'title': title,
        'content': body,
        if (department != null && department.trim().isNotEmpty) 'department': department,
      });
      final json = response.data;
      if (json is! Map<String, dynamic>) {
        throw const AnnouncementException('malformed_contract', 'error_invalid_response');
      }
      return _parseJsonOrThrow(json);
    } on DioException catch (e) {
      throw _mapDioException(e);
    } catch (e) {
      if (e is AnnouncementException) rethrow;
      throw const AnnouncementException('server_error', 'error_server');
    }
  }

  AnnouncementException _mapDioException(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError) {
      return const AnnouncementException('network_error', 'error_network');
    }

    final statusCode = e.response?.statusCode;
    if (statusCode == 400) return const AnnouncementException('bad_request', 'error_bad_request');
    if (statusCode == 401) return const AnnouncementException('unauthorized', 'error_unauthorized');
    if (statusCode == 403) return const AnnouncementException('forbidden', 'error_forbidden');
    if (statusCode == 404) return const AnnouncementException('not_found', 'error_not_found');

    return const AnnouncementException('server_error', 'error_server');
  }

  Announcement _parseJsonOrThrow(Map<String, dynamic> json) {
    try {
      final id = json['id'];
      final title = json['title'];
      final content = json['content'];
      final createdAt = json['createdAt'];
      final department = json['department'];

      if (id is! String || id.trim().isEmpty ||
          title is! String || title.trim().isEmpty ||
          content is! String || content.trim().isEmpty ||
          createdAt is! String || createdAt.trim().isEmpty) {
        throw const AnnouncementException('malformed_contract', 'error_invalid_response');
      }

      if (department != null && department is! String) {
        throw const AnnouncementException('malformed_contract', 'error_invalid_response');
      }

      final date = DateTime.parse(createdAt);
      return Announcement(
        id: id,
        title: title,
        body: content,
        date: date,
        department: department,
      );
    } catch (_) {
      throw const AnnouncementException('malformed_contract', 'error_invalid_response');
    }
  }
}
