
import 'system_config_settings_card.dart';
import '../../../../core/widgets/web_shimmer_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/bloc/web_cubits.dart';
import '../bloc/system_config_cubit.dart';

class DepartmentsContent extends StatelessWidget {
  const DepartmentsContent({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SystemConfigCubit, WebState<SystemConfigState>>(
      builder: (context, state) {
        if (state is WebSuccess<SystemConfigState>) {
          final depts = state.data.departments;
          return SettingsCard(title: 'Departments', child: Column(children: [
            ...depts.map((d) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(children: [
                Container(padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                  child: Icon(Iconsax.buildings, size: 14, color: AppColors.primary)),
                const SizedBox(width: 12),
                Expanded(child: Text(d.name, style: const TextStyle(fontWeight: FontWeight.w500))),
                Text('${d.headcount} employees', style: const TextStyle(color: Colors.grey)),
              ]),
            )),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Iconsax.add, size: 16),
              label: const Text('Add Department'),
              onPressed: () => _showAddDeptDialog(context),
            ),
          ]));
        }
        if (state is WebError<SystemConfigState>) return Center(child: Text(state.message, style: const TextStyle(color: Colors.red))); return const ShimmerLoading();
      },
    );
  }

  void _showAddDeptDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Department'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Department Name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.isNotEmpty) {
                context.read<SystemConfigCubit>().addDepartment(ctrl.text);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
