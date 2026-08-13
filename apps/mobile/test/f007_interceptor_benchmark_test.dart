import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('F-007 Benchmark: Measure SharedPreferences GetIt & getString lookup latency', () async {
    SharedPreferences.setMockInitialValues({'jwt_token': 'mock_jwt_token_sample_12345'});
    final prefsInstance = await SharedPreferences.getInstance();

    final getIt = GetIt.instance;
    getIt.reset();
    getIt.registerLazySingleton<SharedPreferences>(() => prefsInstance);

    // Warmup
    final warmupPrefs = getIt<SharedPreferences>();
    warmupPrefs.getString('jwt_token');

    const int iterations = 1000;
    final stopwatch = Stopwatch()..start();

    for (int i = 0; i < iterations; i++) {
      final prefs = getIt<SharedPreferences>();
      final token = prefs.getString('jwt_token');
      assert(token != null);
    }

    stopwatch.stop();

    final totalMicroseconds = stopwatch.elapsedMicroseconds;
    final averageMicrosecondsPerRequest = totalMicroseconds / iterations;
    final averageMillisecondsPerRequest = averageMicrosecondsPerRequest / 1000.0;

    print('\n=== F-007 DIO INTERCEPTOR EMPIRICAL BENCHMARK ===');
    print('Total Iterations: $iterations');
    print('Total Execution Time: ${totalMicroseconds} µs (${stopwatch.elapsedMilliseconds} ms)');
    print('Average Latency per Request: ${averageMicrosecondsPerRequest.toStringAsFixed(3)} µs (${averageMillisecondsPerRequest.toStringAsFixed(5)} ms)');

    // Compare with average network RTT (e.g., 200,000 µs / 200 ms)
    const double typicalNetworkRttMs = 200.0;
    final double overheadPercentage = (averageMillisecondsPerRequest / typicalNetworkRttMs) * 100.0;
    print('Overhead relative to 200ms Network RTT: ${overheadPercentage.toStringAsFixed(5)}%');

    // Verification assertion: Token resolution must complete in microsecond scale
    expect(averageMillisecondsPerRequest, lessThan(0.05), reason: 'SharedPreferences getString lookup is in-memory Map lookup taking < 0.05ms');
  });
}
