import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:hr_core/features/communication/data/datasources/api_announcement_datasource.dart';
import 'package:hr_core/features/communication/domain/errors/announcement_exception.dart';

void main() {
  late ApiAnnouncementDataSource dataSource;
  late Dio dio;

  setUp(() {
    dio = Dio();
    dio.httpClientAdapter = _MockHttpClientAdapter();
    dataSource = ApiAnnouncementDataSource(dio: dio);
  });

  group('ApiAnnouncementDataSource', () {
    test('getAnnouncements throws AnnouncementException on malformed list response', () async {
      _MockHttpClientAdapter.mockResponse = ResponseBody.fromString(
        jsonEncode({'error': 'not a list'}),
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
      _MockHttpClientAdapter.throwDioException = false;

      expect(() => dataSource.getAnnouncements(), throwsA(isA<AnnouncementException>()));
    });

    test('getAnnouncements throws AnnouncementException on missing required fields', () async {
      _MockHttpClientAdapter.mockResponse = ResponseBody.fromString(
        jsonEncode([{'title': 'only title'}]), // Missing id, content, createdAt
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
      _MockHttpClientAdapter.throwDioException = false;

      expect(() => dataSource.getAnnouncements(), throwsA(isA<AnnouncementException>()));
    });

    test('getAnnouncements throws AnnouncementException on invalid date', () async {
      _MockHttpClientAdapter.mockResponse = ResponseBody.fromString(
        jsonEncode([{'id': '1', 'title': 'T', 'content': 'C', 'createdAt': 'not a date'}]),
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
      _MockHttpClientAdapter.throwDioException = false;

      expect(() => dataSource.getAnnouncements(), throwsA(isA<AnnouncementException>()));
    });

    test('getAnnouncements throws AnnouncementException on invalid field type', () async {
      _MockHttpClientAdapter.mockResponse = ResponseBody.fromString(
        jsonEncode([{'id': 123, 'title': 'T', 'content': 'C', 'createdAt': '2026-08-27T12:00:00Z'}]),
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
      _MockHttpClientAdapter.throwDioException = false;

      expect(() => dataSource.getAnnouncements(), throwsA(isA<AnnouncementException>()));
    });

    test('addAnnouncement bubbles up 400 validation error correctly', () async {
      _MockHttpClientAdapter.throwDioException = true;
      _MockHttpClientAdapter.mockDioException = DioException(
        requestOptions: RequestOptions(path: '/communication/announcements'),
        response: Response(
          requestOptions: RequestOptions(path: '/'),
          data: {'message': 'Title must be less than 100 characters'},
          statusCode: 400,
        ),
        type: DioExceptionType.badResponse,
      );

      try {
        await dataSource.addAnnouncement('Long Title', 'Body');
        fail('Should have thrown');
      } on AnnouncementException catch (e) {
        expect(e.code, 'bad_request');
        expect(e.messageKey, 'error_bad_request');
      }
    });
  });
}

class _MockHttpClientAdapter implements HttpClientAdapter {
  static ResponseBody? mockResponse;
  static bool throwDioException = false;
  static DioException? mockDioException;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    if (throwDioException && mockDioException != null) {
      throw mockDioException!;
    }
    return mockResponse!;
  }

  @override
  void close({bool force = false}) {}
}
