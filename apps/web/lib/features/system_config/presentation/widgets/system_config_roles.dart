
import 'package:hr_core/core/enums/role_enums.dart';
import 'system_config_settings_card.dart';
import '../../../../core/widgets/web_shimmer_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hr_core/features/admin/domain/entities/system_config_entities.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/bloc/web_cubits.dart';
import '../bloc/system_config_cubit.dart';

class RolesContent extends StatelessWidget {
  const RolesContent({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SystemConfigCubit, WebState<SystemConfigState>>(
      builder: (context, state) {
        if (state is WebSuccess<SystemConfigState>) {
          final perms = state.data.rolePermissions;
          return SettingsCard(title: 'Role & Permission Matrix', child: Column(children: [
            Table(
              columnWidths: const {0: FlexColumnWidth(1.5), 1: FlexColumnWidth(1), 2: FlexColumnWidth(1), 3: FlexColumnWidth(1), 4: FlexColumnWidth(1)},
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                  children: ['Permission', 'Employee', 'Manager', 'HR Admin', 'Super Admin'].map((h) =>
                    Padding(padding: const EdgeInsets.all(12), child: Text(h, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))).toList(),
                ),
                ...['approveLeave', 'viewPayroll', 'systemConfig'].map((key) {
                  return TableRow(
                    children: [
                      Padding(padding: const EdgeInsets.all(12), child: Text(key, style: const TextStyle(fontSize: 12))),
                      ...[UserRole.employee, UserRole.manager, UserRole.hrAdmin, UserRole.superAdmin].map((role) {
                        final perm = perms.firstWhere((p) => p.role == role && p.featureKey == key,
                          orElse: () => RolePermission(role: role, featureKey: key, allowed: false));
                        return Padding(
                          padding: const EdgeInsets.all(8),
                          child: Switch(
                            value: perm.allowed,
                            onChanged: (_) => context.read<SystemConfigCubit>().toggleRolePermission(role, key),
                            activeColor: AppColors.primary,
                          ),
                        );
                      }),
                    ],
                  );
                }),
              ],
            ),
          ]));
        }
        if (state is WebError<SystemConfigState>) return Center(child: Text(state.message, style: const TextStyle(color: Colors.red))); return const ShimmerLoading();
      },
    );
  }
}
