import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    test('1. Missing API_BASE_URL in Web initDI throws StateError', () async {
      await getIt.reset();
      expect(() => initDI(), throwsA(isA<StateError>()));
    });

    testWidgets(
        '2. Web login renders employeeCode and password fields, and no static role pickers',
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
  });
}
