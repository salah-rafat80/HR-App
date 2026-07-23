import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import 'package:hr_app_demo/core/widgets/app_loader.dart';
import 'package:hr_app_demo/core/bloc/session_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:hr_app_demo/core/di/injection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  bool _isLoading = false;
  final _emailController = TextEditingController(text: 'employee@demo.com');
  final _passwordController = TextEditingController(text: 'password123');

  void _simulateLogin() async {
    setState(() => _isLoading = true);
    
    try {
      final dio = getIt<Dio>();
      final response = await dio.post('/auth/login', data: {
        'email': _emailController.text,
        'password': _passwordController.text,
      });

      final token = response.data['access_token'];
      final prefs = getIt<SharedPreferences>();
      await prefs.setString('jwt_token', token);
      
      // Connect socket after successful login
      final socket = getIt<IO.Socket>();
      socket.connect();

      if (!mounted) return;
      context.read<SessionCubit>().setAuthenticated(true);
      context.go(AppRoutes.home);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: 'البريد الإلكتروني / Email',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        SizedBox(height: 16.h),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'كلمة المرور / Password',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        SizedBox(height: 32.h),
        ElevatedButton(
          onPressed: _isLoading ? null : _simulateLogin,
          child: _isLoading 
            ? const SizedBox(
                width: 24, 
                height: 24, 
                child: AppLoader(size: 24)
              )
            : Text('login_button'.tr(), style: TextStyle(fontSize: 16.sp)),
        ),
      ],
    );
  }
}
