import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_it/get_it.dart';
import 'package:hr_app_demo/core/bloc/session_cubit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('F-002 Session Test: checkStoredSession returns true if token exists and false if null', () async {
    SharedPreferences.setMockInitialValues({'jwt_token': 'sample_jwt_123'});
    final prefsInstance = await SharedPreferences.getInstance();

    final getIt = GetIt.instance;
    await getIt.reset();
    getIt.registerLazySingleton<SharedPreferences>(() => prefsInstance);

    final sessionCubit = SessionCubit();
    final auth1 = await sessionCubit.checkStoredSession();
    expect(auth1, isTrue);
    expect(sessionCubit.state, isTrue);

    // Clear token
    await prefsInstance.remove('jwt_token');
    final auth2 = await sessionCubit.checkStoredSession();
    expect(auth2, isFalse);
    expect(sessionCubit.state, isFalse);
  });
}
