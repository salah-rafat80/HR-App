import 'package:local_auth/local_auth.dart';

abstract class BiometricService {
  Future<bool> isBiometricAvailable();
  Future<bool> authenticateBiometricOnly(String reason);
}

class BiometricServiceImpl implements BiometricService {
  final LocalAuthentication _auth;

  BiometricServiceImpl({LocalAuthentication? auth})
      : _auth = auth ?? LocalAuthentication();

  @override
  Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> authenticateBiometricOnly(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
