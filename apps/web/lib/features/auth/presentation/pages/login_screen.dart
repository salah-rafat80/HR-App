import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hr_core/core/enums/role_enums.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/bloc/session_cubit.dart';
import '../../../../core/router/app_routes.dart';
import 'package:dio/dio.dart';
import '../../../../core/di/injection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Left branding panel
          Expanded(
            flex: 5,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF063B36), Color(0xFF0B6E64), Color(0xFF168F83)],
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
                      child: const Icon(Iconsax.activity, size: 64, color: Colors.white),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'HR Admin Portal',
                      style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Manage your organization at scale',
                      style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.7)),
                    ),
                    const SizedBox(height: 48),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildStat('142', 'Employees'),
                          const SizedBox(width: 40),
                          _buildStat('5', 'Departments'),
                          const SizedBox(width: 40),
                          _buildStat('98%', 'Uptime'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Right login panel
          Expanded(
            flex: 4,
            child: Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              body: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: _LoginForm(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.7))),
      ],
    );
  }
}

class _LoginForm extends StatelessWidget {
  _LoginForm();

  final List<Map<String, dynamic>> roles = [
    {'role': UserRole.teamLead, 'label': 'Team Lead', 'icon': Iconsax.people, 'subtitle': 'Manage your team'},
    {'role': UserRole.manager, 'label': 'Manager', 'icon': Iconsax.user_edit, 'subtitle': 'Department oversight'},
    {'role': UserRole.hrAdmin, 'label': 'HR Admin', 'icon': Iconsax.security_user, 'subtitle': 'Full HR operations'},
    {'role': UserRole.superAdmin, 'label': 'Super Admin', 'icon': Iconsax.shield_tick, 'subtitle': 'System configuration'},
    {'role': UserRole.cLevel, 'label': 'C-Level Executive', 'icon': Iconsax.chart_square, 'subtitle': 'Analytics & insights'},
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Welcome back', style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 8),
        Text('Select your role to continue', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 15)),
        const SizedBox(height: 40),
        ...roles.map((r) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _RoleButton(
            role: r['role'] as UserRole,
            label: r['label'] as String,
            subtitle: r['subtitle'] as String,
            icon: r['icon'] as IconData,
          ),
        )),
      ],
    );
  }
}

class _RoleButton extends StatefulWidget {
  final UserRole role;
  final String label;
  final String subtitle;
  final IconData icon;
  const _RoleButton({required this.role, required this.label, required this.subtitle, required this.icon});

  @override
  State<_RoleButton> createState() => _RoleButtonState();
}

class _RoleButtonState extends State<_RoleButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: _hovered ? AppColors.primary.withValues(alpha: 0.06) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _hovered ? AppColors.primary.withValues(alpha: 0.5) : cs.outlineVariant,
            width: _hovered ? 1.5 : 1,
          ),
          boxShadow: _hovered ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))] : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () async {
              try {
                String email = 'employee@demo.com';
                if (widget.role == UserRole.manager) email = 'manager@demo.com';
                if (widget.role == UserRole.hrAdmin || widget.role == UserRole.superAdmin) email = 'hr@demo.com';

                final dio = getIt<Dio>();
                final response = await dio.post('/auth/login', data: {
                  'email': email,
                  'password': 'password123',
                });

                final token = response.data['access_token'];
                final prefs = getIt<SharedPreferences>();
                await prefs.setString('jwt_token', token);
                
                final socket = getIt<IO.Socket>();
                socket.connect();

                if (!context.mounted) return;
                context.read<SessionCubit>().setRole(widget.role);
                context.go(AppRoutes.dashboard);
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login failed')));
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _hovered ? AppColors.primary.withValues(alpha: 0.15) : cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(widget.icon, size: 20, color: _hovered ? AppColors.primary : cs.onSurfaceVariant),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 2),
                        Text(widget.subtitle, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                      ],
                    ),
                  ),
                  Icon(Iconsax.arrow_right_3, size: 18, color: _hovered ? AppColors.primary : cs.onSurfaceVariant),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
