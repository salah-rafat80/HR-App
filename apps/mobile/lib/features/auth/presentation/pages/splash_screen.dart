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
    final isAuthenticated = await context.read<SessionCubit>().checkStoredSession();
    if (!mounted) return;

    if (isAuthenticated) {
      final notificationConsumed = await FcmService.instance.consumePendingNotification(context);
      if (!notificationConsumed && mounted) {
        context.go(AppRoutes.home);
      }
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: SplashLogo(),
      ),
    );
  }
}
