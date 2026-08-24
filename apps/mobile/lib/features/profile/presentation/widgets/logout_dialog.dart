import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/bloc/session_cubit.dart';

class LogoutDialog extends StatelessWidget {
  const LogoutDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<SessionCubit>(),
        child: const LogoutDialog(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('confirm_logout'.tr()),
      content: Text('confirm_logout_msg'.tr()),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('cancel'.tr()),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
          ),
          onPressed: () async {
            final cubit = context.read<SessionCubit>();
            Navigator.pop(context);
            await cubit.logout();
            if (!context.mounted) return;
            context.go(AppRoutes.login);
          },
          child: Text('logout'.tr()),
        ),
      ],
    );
  }
}
