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
  @override
  void initState() {
    super.initState();
    _initStartupRouting();
  }

  Future<void> _initStartupRouting() async {
    try {
      final sessionState = await context
          .read<SessionCubit>()
          .checkStoredSession()
          .timeout(const Duration(seconds: 3), onTimeout: () {
        return const SessionState(
          status: SessionStatus.sessionUnknown,
          errorMessage: 'Server connection timeout. Navigating to login.',
        );
      });

      if (!mounted) return;

      if (sessionState.status == SessionStatus.authenticated) {
        final notificationConsumed =
            await FcmService.instance.consumePendingNotification(context);
        if (!notificationConsumed && mounted) {
          context.go(AppRoutes.home);
        }
      } else if (sessionState.status == SessionStatus.sessionUnknown) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(sessionState.errorMessage ??
                  'Server unavailable. Please sign in again.'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
          context.go(AppRoutes.login);
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SplashLogo(),
            const SizedBox(height: 36),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
