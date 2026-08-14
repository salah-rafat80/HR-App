import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_it/get_it.dart';
import 'package:hr_app_demo/core/di/injection.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('F-001 Startup Audit: Measure individual blocking initialization step latencies', () async {
    SharedPreferences.setMockInitialValues({'jwt_token': 'mock_jwt'});

    final swTotal = Stopwatch()..start();

    // Step 1: Measure SharedPreferences disk initialization
    final swPrefs = Stopwatch()..start();
    final prefs = await SharedPreferences.getInstance();
    swPrefs.stop();

    // Step 2: Measure Dependency Injection setup
    final swDi = Stopwatch()..start();
    final getIt = GetIt.instance;
    await getIt.reset();
    await initDI(overrideBaseUrl: 'http://localhost:3000');
    swDi.stop();

    swTotal.stop();

    print('\n=== F-001 STARTUP INITIALIZATION AUDIT METRICS ===');
    print('SharedPreferences.getInstance() Latency: ${swPrefs.elapsedMicroseconds} µs (${swPrefs.elapsedMilliseconds} ms)');
    print('initDI() Latency: ${swDi.elapsedMicroseconds} µs (${swDi.elapsedMilliseconds} ms)');
    print('Total Critical Inits Blocking runApp(): ${swTotal.elapsedMicroseconds} µs (${swTotal.elapsedMilliseconds} ms)');
    print('==================================================\n');

    expect(prefs, isNotNull);
    expect(getIt.isRegistered<SharedPreferences>(), isTrue);
  });
}
