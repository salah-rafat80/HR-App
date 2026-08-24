import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/bloc/session_cubit.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/services/fcm_service.dart';
import '../widgets/splash_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initStartupRouting();
  }

  Future<void> _initStartupRouting() async {
    setState(() {
      _errorMessage = null;
    });

    try {
      final sessionState = await context
          .read<SessionCubit>()
          .checkStoredSession()
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              return const SessionState(
                status: SessionStatus.sessionUnknown,
                errorMessage:
                    'Server connection timeout. Retrying recommended.',
              );
            },
          );

      if (!mounted) return;

      if (sessionState.status == SessionStatus.authenticated) {
        final notificationConsumed = await FcmService.instance
            .consumePendingNotification(context);
        if (!notificationConsumed && mounted) {
          context.go(AppRoutes.home);
        }
      } else if (sessionState.status == SessionStatus.sessionUnknown) {
        if (mounted) {
          setState(() {
            _errorMessage =
                sessionState.errorMessage ??
                'Session verification unavailable. Check connection.';
          });
        }
      } else {
        context.go(AppRoutes.login);
      }
    } catch (_) {
      if (mounted) {
        context.go(AppRoutes.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SplashLogo(),
              const SizedBox(height: 36),
              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.orange.shade800,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _initStartupRouting,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry Verification'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.go(AppRoutes.login),
                  child: const Text('Proceed to Login'),
                ),
              ] else ...[
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
