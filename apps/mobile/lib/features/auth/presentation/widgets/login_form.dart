import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/bloc/session_cubit.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/fcm_service.dart';
import '../../../../core/services/token_service.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  bool _isLoading = false;
  final _employeeCodeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _employeeCodeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final employeeCode = _employeeCodeController.text.trim();
    final password = _passwordController.text;

    try {
      final dio = getIt<Dio>();
      final response = await dio.post(
        '/auth/login',
        data: {'employeeCode': employeeCode, 'password': password},
      );

      final token = response.data['access_token'] as String?;
      final refreshToken = response.data['refresh_token'] as String?;
      if (token == null || token.isEmpty) {
        throw Exception('Invalid token returned');
      }

      final tokenService = getIt<TokenService>();
      await tokenService.saveAccessToken(token);
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await tokenService.saveRefreshToken(refreshToken);
      }

      try {
        final socket = getIt<io.Socket>();
        socket.connect();
      } catch (_) {}

      try {
        final fcmToken = await FcmService.instance.getToken();
        if (fcmToken != null) {
          await dio.patch('/auth/fcm-token', data: {'fcmToken': fcmToken});
        }
      } catch (e) {
        debugPrint('FCM Token registration failed: $e');
      }

      String? role;
      try {
        final me = await dio.get('/auth/me');
        if (me.data is Map) role = me.data['role']?.toString();
      } catch (_) {
        // The backend remains the authorization source; a missing role only
        // hides role-specific navigation until the next verified session check.
      }

      if (!mounted) return;
      context.read<SessionCubit>().setAuthenticated(true, role: role);
      context.go(AppRoutes.home);
    } catch (e) {
      if (!mounted) return;
      String errorMsg = 'Invalid employee code or password';
      if (e is DioException) {
        if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
          errorMsg = 'Invalid employee code or password';
        } else if (e.response?.statusCode != null &&
            e.response!.statusCode! >= 500) {
          errorMsg = 'Server error. Please try again later.';
        } else if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.connectionError) {
          errorMsg = 'Unable to connect to server. Check network connection.';
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            key: const Key('employeeCodeField'),
            controller: _employeeCodeController,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: 'كود الموظف / Employee Code',
              prefixIcon: const Icon(Icons.badge_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your employee code';
              }
              return null;
            },
          ),
          SizedBox(height: 16.h),
          TextFormField(
            key: const Key('passwordField'),
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'كلمة المرور / Password',
              prefixIcon: const Icon(Icons.lock_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              return null;
            },
          ),
          SizedBox(height: 32.h),
          SizedBox(
            width: double.infinity,
            height: 48.h,
            child: ElevatedButton(
              key: const Key('loginButton'),
              onPressed: _isLoading ? null : _handleLogin,
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: AppLoader(size: 24),
                    )
                  : Text(
                      'login_button'.tr(),
                      style: TextStyle(fontSize: 16.sp),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
