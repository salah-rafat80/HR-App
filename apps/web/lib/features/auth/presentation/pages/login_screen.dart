import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:hr_core/core/enums/role_enums.dart';
import 'package:hr_core/core/services/token_storage.dart';
import '../../../../core/bloc/session_cubit.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/di/injection.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Expanded(
            flex: 5,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF063B36),
                    Color(0xFF0B6E64),
                    Color(0xFF168F83)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Iconsax.activity,
                          size: 64, color: Colors.white),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'HR Admin Portal',
                      style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Single-Company Enterprise HR Portal',
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              body: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: const Padding(
                    padding: EdgeInsets.all(32),
                    child: WebLoginForm(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WebLoginForm extends StatefulWidget {
  const WebLoginForm({super.key});

  @override
  State<WebLoginForm> createState() => _WebLoginFormState();
}

class _WebLoginFormState extends State<WebLoginForm> {
  final _employeeCodeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _employeeCodeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  UserRole _parseRole(String? roleStr) {
    if (roleStr == null) return UserRole.employee;
    switch (roleStr.toLowerCase()) {
      case 'team_lead':
      case 'teamlead':
        return UserRole.teamLead;
      case 'manager':
        return UserRole.manager;
      case 'hr_admin':
      case 'hradmin':
      case 'hr':
        return UserRole.hrAdmin;
      case 'super_admin':
      case 'superadmin':
      case 'admin':
        return UserRole.superAdmin;
      case 'c_level':
      case 'clevel':
        return UserRole.cLevel;
      default:
        return UserRole.employee;
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final employeeCode = _employeeCodeController.text.trim();
    final password = _passwordController.text;

    try {
      final dio = getIt<Dio>();
      final response = await dio.post('/auth/login', data: {
        'employeeCode': employeeCode,
        'password': password,
      });

      final token = response.data['access_token'] as String?;
      if (token == null || token.isEmpty) {
        throw Exception('Invalid authentication response');
      }

      final tokenStorage = getIt<TokenStorage>();
      await tokenStorage.saveToken(token);

      final roleStr = response.data['user']?['role'] as String?;
      final userRole = _parseRole(roleStr);

      try {
        final socket = getIt<io.Socket>();
        socket.connect();
      } catch (_) {}

      if (!mounted) return;
      context.read<SessionCubit>().setAuthenticatedRole(userRole);
      context.go(AppRoutes.dashboard);
    } catch (e) {
      if (!mounted) return;
      String errorMsg = 'Invalid employee code or password';
      if (e is DioException) {
        if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
          errorMsg = 'Invalid employee code or password';
        } else if (e.response?.statusCode != null &&
            e.response!.statusCode! >= 500) {
          errorMsg = 'Server connection failed. Try again later.';
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Welcome back',
              style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 8),
          Text('Sign in with your employee code',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 15)),
          const SizedBox(height: 32),
          TextFormField(
            key: const Key('webEmployeeCodeField'),
            controller: _employeeCodeController,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: 'Employee Code',
              prefixIcon: const Icon(Iconsax.personalcard),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Please enter your employee code';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            key: const Key('webPasswordField'),
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Iconsax.lock_1),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (val) {
              if (val == null || val.isEmpty) {
                return 'Please enter your password';
              }
              return null;
            },
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              key: const Key('webLoginButton'),
              onPressed: _isLoading ? null : _handleLogin,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Sign In',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
