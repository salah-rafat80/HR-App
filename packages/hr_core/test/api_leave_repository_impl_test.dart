import 'dart:convert';
import 'package:test/test.dart';
import 'package:dio/dio.dart';
import 'package:hr_core/features/leave/data/datasources/api_leave_repository_impl.dart';
import 'package:hr_core/features/leave/domain/entities/leave_enums.dart';
import 'package:hr_core/features/leave/domain/entities/leave_policy.dart';
import 'package:hr_core/core/enums/role_enums.dart';

class FakeDioAdapter implements HttpClientAdapter {
  ResponseBody? responseBody;
  RequestOptions? lastRequestOptions;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequestOptions = options;
    if (responseBody == null) {
      throw StateError('FakeDioAdapter responseBody not set');
    }
    return responseBody!;
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('ApiLeaveRepositoryImpl - Strict API Contract Enforcement', () {
    late Dio dio;
    late ApiLeaveRepositoryImpl repository;

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
      repository = ApiLeaveRepositoryImpl(dio: dio);
    });

    test('createPolicy sends POST body without id property', () async {
      final adapter = FakeDioAdapter();
      adapter.responseBody = ResponseBody.fromString(
        jsonEncode({'success': true}),
        201,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
      dio.httpClientAdapter = adapter;

      const policy = LeavePolicy(
        id: 'should-be-omitted',
        type: LeaveType.annual,
        displayNameAr: 'إجازة سنوية',
        annualEntitlement: 21.0,
        isPaid: true,
        requiresBalance: true,
        allowHalfDay: true,
        minimumNoticeDays: 3,
        requiresReason: true,
        isActive: true,
      );

      await repository.createPolicy(policy);

      expect(adapter.lastRequestOptions, isNotNull);
      final body = adapter.lastRequestOptions!.data as Map<String, dynamic>;
      expect(body.containsKey('id'), isFalse);
      expect(body['type'], equals('annual'));
      expect(body['displayNameAr'], equals('إجازة سنوية'));
    });

    test('getPendingApprovals parses valid pagination envelope', () async {
      dio.httpClientAdapter = _createAdapter({
        'total': 1,
        'page': 1,
        'limit': 10,
        'totalPages': 1,
        'items': [
          {
            'id': 'req-101',
            'userId': 'user-1',
            'type': 'annual',
            'startDate': '2026-08-25',
            'endDate': '2026-08-27',
            'isHalfDay': false,
            'reason': 'Vacation',
            'hasAttachment': false,
            'overallStatus': 'pending',
            'currentStepOrder': 1,
            'workingDays': 3,
            'createdAt': '2026-08-22T10:00:00.000Z',
            'updatedAt': '2026-08-22T10:00:00.000Z',
            'approvalSteps': [],
            'user': {
              'id': 'user-1',
              'name': 'John Doe',
              'employeeCode': 'EMP101',
              'department': 'IT',
              'branchId': 'branch-1',
              'role': 'employee',
            },
          }
        ],
      }, 200);

      final requests = await repository.getPendingApprovals(ApprovalScope.all);
      expect(requests, hasLength(1));
      expect(requests.first.id, equals('req-101'));
    });

    test('getPendingApprovals throws StateError on non-Map response', () async {
      dio.httpClientAdapter = _createAdapter(['invalid'], 200);
      expect(
        () => repository.getPendingApprovals(ApprovalScope.all),
        throwsA(isA<StateError>().having((e) => e.message, 'message',
            contains('expected pagination object'))),
      );
    });

    test('getPendingApprovals throws StateError on non-List items', () async {
      dio.httpClientAdapter = _createAdapter({'items': 'invalid'}, 200);
      expect(
        () => repository.getPendingApprovals(ApprovalScope.all),
        throwsA(isA<StateError>().having(
            (e) => e.message, 'message', contains('expected items list'))),
      );
    });

    test('getPendingApprovals throws StateError on malformed list element',
        () async {
      dio.httpClientAdapter = _createAdapter({
        'total': 1,
        'page': 1,
        'limit': 10,
        'totalPages': 1,
        'items': ['malformed_item_string'],
      }, 200);

      expect(
        () => repository.getPendingApprovals(ApprovalScope.all),
        throwsA(isA<StateError>()
            .having((e) => e.message, 'message', contains('expected Map'))),
      );
    });

    test('getBalancesAdmin throws StateError when payload is not a Map',
        () async {
      dio.httpClientAdapter = _createAdapter(['invalid', 'array'], 200);
      expect(
        () => repository.getBalancesAdmin(page: 1, limit: 10),
        throwsA(isA<StateError>().having((e) => e.message, 'message',
            contains('expected pagination object'))),
      );
    });

    test('getBalancesAdmin throws StateError when items is not a List',
        () async {
      dio.httpClientAdapter = _createAdapter({'items': 'invalid_items'}, 200);
      expect(
        () => repository.getBalancesAdmin(page: 1, limit: 10),
        throwsA(isA<StateError>().having(
            (e) => e.message, 'message', contains('expected items list'))),
      );
    });

    test('getBalancesAdmin throws StateError on malformed list element',
        () async {
      dio.httpClientAdapter = _createAdapter({
        'items': [12345]
      }, 200);
      expect(
        () => repository.getBalancesAdmin(page: 1, limit: 10),
        throwsA(isA<StateError>()
            .having((e) => e.message, 'message', contains('expected Map'))),
      );
    });

    test('getPolicies throws StateError when response is not a List', () async {
      dio.httpClientAdapter = _createAdapter({'error': 'object'}, 200);
      expect(
        () => repository.getPolicies(),
        throwsA(isA<StateError>()
            .having((e) => e.message, 'message', contains('expected List'))),
      );
    });

    test('getPolicies throws StateError on malformed list element', () async {
      dio.httpClientAdapter = _createAdapter(['malformed_string_element'], 200);
      expect(
        () => repository.getPolicies(),
        throwsA(isA<StateError>()
            .having((e) => e.message, 'message', contains('expected Map'))),
      );
    });

    test('getBalances throws StateError when response is not a List', () async {
      dio.httpClientAdapter = _createAdapter({'error': 'object'}, 200);
      expect(
        () => repository.getBalances(),
        throwsA(isA<StateError>()
            .having((e) => e.message, 'message', contains('expected List'))),
      );
    });

    test('getBalances throws StateError on malformed list element', () async {
      dio.httpClientAdapter = _createAdapter(['invalid_element'], 200);
      expect(
        () => repository.getBalances(),
        throwsA(isA<StateError>()
            .having((e) => e.message, 'message', contains('expected Map'))),
      );
    });

    test('getMyRequests throws StateError when response is not a List',
        () async {
      dio.httpClientAdapter = _createAdapter({'error': 'object'}, 200);
      expect(
        () => repository.getMyRequests(),
        throwsA(isA<StateError>()
            .having((e) => e.message, 'message', contains('expected List'))),
      );
    });

    test('getMyRequests throws StateError on malformed list element', () async {
      dio.httpClientAdapter = _createAdapter([9999], 200);
      expect(
        () => repository.getMyRequests(),
        throwsA(isA<StateError>()
            .having((e) => e.message, 'message', contains('expected Map'))),
      );
    });

    test('getTeamCalendar throws StateError when response is not a List',
        () async {
      dio.httpClientAdapter = _createAdapter({'error': 'object'}, 200);
      expect(
        () => repository.getTeamCalendar(),
        throwsA(isA<StateError>()
            .having((e) => e.message, 'message', contains('expected List'))),
      );
    });

    test('getTeamCalendar throws StateError on malformed list element',
        () async {
      dio.httpClientAdapter = _createAdapter([true], 200);
      expect(
        () => repository.getTeamCalendar(),
        throwsA(isA<StateError>()
            .having((e) => e.message, 'message', contains('expected Map'))),
      );
    });

    test('getEmployeesForPicker returns safe employee list on valid response',
        () async {
      dio.httpClientAdapter = _createAdapter([
        {
          'id': 'emp-1',
          'name': 'Jane HR',
          'employeeCode': 'HR001',
          'department': 'HR',
          'branchId': 'branch-1',
          'role': 'hr',
        }
      ], 200);

      final employees = await repository.getEmployeesForPicker();
      expect(employees, hasLength(1));
      expect(employees.first['id'], equals('emp-1'));
    });

    test('getEmployeesForPicker throws StateError when response is not a List',
        () async {
      dio.httpClientAdapter = _createAdapter({'error': 'object'}, 200);
      expect(
        () => repository.getEmployeesForPicker(),
        throwsA(isA<StateError>()
            .having((e) => e.message, 'message', contains('expected List'))),
      );
    });

    test('getEmployeesForPicker throws StateError on malformed list element',
        () async {
      dio.httpClientAdapter = _createAdapter(['invalid_string_emp'], 200);
      expect(
        () => repository.getEmployeesForPicker(),
        throwsA(isA<StateError>()
            .having((e) => e.message, 'message', contains('expected Map'))),
      );
    });
  });
}

HttpClientAdapter _createAdapter(dynamic data, int statusCode) {
  final adapter = FakeDioAdapter();
  adapter.responseBody = ResponseBody.fromString(
    jsonEncode(data),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
  return adapter;
}
