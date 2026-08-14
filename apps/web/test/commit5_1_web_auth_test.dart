import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:hr_core/core/services/token_storage.dart';
import 'package:hr_web/features/auth/presentation/pages/login_screen.dart';
import 'package:hr_web/core/di/injection.dart';

class TestTokenStorage implements TokenStorage {
  String? token;
  @override
  Future<void> saveToken(String val) async => token = val;
  @override
  Future<String?> getToken() async => token;
  @override
  Future<void> clearToken() async => token = null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Commit 5.1 — Web Auth Contract & Security', () {
    test(
        '1. Missing, blank, or whitespace-only API_BASE_URL in Web initDI throws StateError',
        () async {
      await getIt.reset();
      expect(() => initDI(), throwsA(isA<StateError>()));

      await getIt.reset();
      expect(() => initDI(overrideBaseUrl: ''), throwsA(isA<StateError>()));

      await getIt.reset();
      expect(() => initDI(overrideBaseUrl: '   '), throwsA(isA<StateError>()));
    });

    test('2. Valid overrideBaseUrl initializes Web Dio client successfully',
        () async {
      await getIt.reset();
      await initDI(overrideBaseUrl: 'http://localhost:3000');
      expect(getIt.isRegistered<Dio>(), isTrue);
      expect(getIt<Dio>().options.baseUrl, equals('http://localhost:3000'));
    });

    testWidgets(
        '3. Web login renders employeeCode and password fields, and no static role pickers',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      expect(find.byKey(const Key('webEmployeeCodeField')), findsOneWidget);
      expect(find.byKey(const Key('webPasswordField')), findsOneWidget);
      expect(find.byKey(const Key('webLoginButton')), findsOneWidget);

      expect(find.text('Team Lead'), findsNothing);
      expect(find.text('Manager'), findsNothing);
      expect(find.text('HR Admin'), findsNothing);
      expect(find.text('Super Admin'), findsNothing);
      expect(find.text('C-Level Executive'), findsNothing);
      expect(find.text('Select your role to continue'), findsNothing);
    });

    test(
        '4. Production web injection.dart file contains NO hard-coded Render URL',
        () {
      final injectionFile = File('lib/core/di/injection.dart');
      expect(injectionFile.existsSync(), isTrue);
      final content = injectionFile.readAsStringSync();
      expect(content.contains('https://hr-app-lswi.onrender.com'), isFalse);
    });
  });
}
