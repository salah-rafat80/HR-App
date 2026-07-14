import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import 'package:hr_app_demo/core/widgets/app_loader.dart';


class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  bool _isLoading = false;

  void _simulateLogin() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _isLoading = false);
    context.go(AppRoutes.roleSelection);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          decoration: InputDecoration(
            labelText: 'البريد الإلكتروني / Email',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        SizedBox(height: 16.h),
        TextField(
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
