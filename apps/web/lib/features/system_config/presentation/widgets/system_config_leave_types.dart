
import 'system_config_settings_card.dart';
import '../../../../core/widgets/web_shimmer_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:hr_core/features/admin/domain/entities/system_config_entities.dart';
import 'package:hr_core/features/leave/domain/entities/leave_enums.dart';
import '../../../../core/bloc/web_cubits.dart';
import '../bloc/system_config_cubit.dart';

class LeaveTypesContent extends StatelessWidget {
  const LeaveTypesContent({super.key});

  Color _colorFor(LeaveType type) {
    switch (type) {
      case LeaveType.annual: return const Color(0xFF22C55E);
      case LeaveType.sick: return const Color(0xFF3B82F6);
      case LeaveType.emergency: return const Color(0xFFF59E0B);
      case LeaveType.maternityPaternity: return const Color(0xFF8B5CF6);
      case LeaveType.unpaid: return Colors.grey;
      default: return Colors.teal;
    }
  }

  String _labelFor(LeaveType type) {
    switch (type) {
      case LeaveType.annual: return 'Annual Leave';
      case LeaveType.sick: return 'Sick Leave';
      case LeaveType.emergency: return 'Emergency Leave';
      case LeaveType.maternityPaternity: return 'Maternity/Paternity';
      case LeaveType.unpaid: return 'Unpaid Leave';
      case LeaveType.study: return 'Study Leave';
      case LeaveType.hajj: return 'Hajj Leave';
      case LeaveType.bereavement: return 'Bereavement Leave';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SystemConfigCubit, WebState<SystemConfigState>>(
      builder: (context, state) {
        if (state is WebSuccess<SystemConfigState>) {
          final types = state.data.leaveTypes;
          return SettingsCard(title: 'Configured Leave Types', child: Column(children: [
            ...types.map((t) => LeaveTypeRow(type: t, color: _colorFor(t.type), label: _labelFor(t.type))),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Iconsax.add, size: 16),
              label: const Text('Add Leave Type'),
              onPressed: () {},
            ),
          ]));
        }
        if (state is WebError<SystemConfigState>) return Center(child: Text(state.message, style: const TextStyle(color: Colors.red))); return const ShimmerLoading();
      },
    );
  }
}

class LeaveTypeRow extends StatelessWidget {
  final LeaveTypeConfig type;
  final Color color;
  final String label;
  const LeaveTypeRow({super.key, required this.type, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500))),
        Text('${type.defaultDaysPerYear} days/year', style: const TextStyle(color: Colors.grey)),
        const SizedBox(width: 16),
        InkWell(
          onTap: () => _showEditDialog(context),
          child: const Icon(Iconsax.edit_2, size: 16, color: Colors.grey),
        ),
      ]),
    );
  }

  void _showEditDialog(BuildContext context) {
    final ctrl = TextEditingController(text: type.defaultDaysPerYear.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit $label'),
        content: TextField(controller: ctrl, keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Days per year')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final days = int.tryParse(ctrl.text);
              if (days != null) {
                context.read<SystemConfigCubit>().updateLeaveType(type.type, days);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
