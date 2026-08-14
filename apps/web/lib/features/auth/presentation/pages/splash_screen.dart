import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hr_core/core/enums/role_enums.dart';
import '../../../../core/bloc/session_cubit.dart';
import '../../../../core/router/app_routes.dart';

class WebSplashScreen extends StatefulWidget {
  const WebSplashScreen({super.key});

  @override
  State<WebSplashScreen> createState() => _WebSplashScreenState();
}

class _WebSplashScreenState extends State<WebSplashScreen> {
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _bootstrapSession();
  }

  Future<void> _bootstrapSession() async {
    setState(() {
      _errorMessage = null;
    });

    try {
      final sessionState = await context
          .read<SessionCubit>()
          .checkStoredSession()
          .timeout(const Duration(seconds: 5), onTimeout: () {
        return const WebSessionState(
          status: WebSessionStatus.sessionUnknown,
          errorMessage: 'Backend connection timeout. Please try again.',
        );
      });

      if (!mounted) return;

      if (sessionState.status == WebSessionStatus.authenticated) {
        final role = sessionState.role ?? UserRole.employee;
        String targetRoute = AppRoutes.dashboard;
        switch (role) {
          case UserRole.teamLead:
          case UserRole.manager:
          case UserRole.hrAdmin:
            targetRoute = AppRoutes.approvals;
            break;
          case UserRole.superAdmin:
          case UserRole.cLevel:
            targetRoute = AppRoutes.executiveDashboard;
            break;
          case UserRole.employee:
            targetRoute = AppRoutes.dashboard;
            break;
        }
        context.go(targetRoute);
      } else if (sessionState.status == WebSessionStatus.sessionUnknown) {
        setState(() {
          _errorMessage = sessionState.errorMessage ??
              'Session verification unavailable. Please check your network connection.';
        });
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
              Icon(
                Icons.business_center,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'HR Enterprise Portal',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
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
                  onPressed: _bootstrapSession,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry Verification'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.go(AppRoutes.login),
                  child: const Text('Return to Login'),
                ),
              ] else ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Verifying session credentials...',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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
