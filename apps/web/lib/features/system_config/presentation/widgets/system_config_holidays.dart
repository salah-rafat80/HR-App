
import 'system_config_settings_card.dart';
import '../../../../core/widgets/web_shimmer_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../core/bloc/web_cubits.dart';
import '../bloc/system_config_cubit.dart';

class HolidaysContent extends StatelessWidget {
  const HolidaysContent({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SystemConfigCubit, WebState<SystemConfigState>>(
      builder: (context, state) {
        if (state is WebSuccess<SystemConfigState>) {
          final holidays = state.data.holidays;
          return SettingsCard(title: 'Public Holidays', child: Column(children: [
            ...holidays.map((h) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(children: [
                const Icon(Iconsax.star, size: 16, color: Color(0xFFF59E0B)),
                const SizedBox(width: 12),
                Expanded(child: Text(h.name, style: const TextStyle(fontWeight: FontWeight.w500))),
                Text('${h.date.day}/${h.date.month}/${h.date.year}', style: const TextStyle(color: Colors.grey)),
              ]),
            )),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Iconsax.add, size: 16),
              label: const Text('Add Holiday'),
              onPressed: () => _showAddHolidayDialog(context),
            ),
          ]));
        }
        if (state is WebError<SystemConfigState>) return Center(child: Text(state.message, style: const TextStyle(color: Colors.red))); return const ShimmerLoading();
      },
    );
  }

  void _showAddHolidayDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    DateTime selected = DateTime.now();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add Holiday'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Holiday Name')),
            const SizedBox(height: 16),
            ListTile(
              title: Text('${selected.day}/${selected.month}/${selected.year}'),
              trailing: const Icon(Iconsax.calendar),
              onTap: () async {
                final picked = await showDatePicker(
                  context: ctx,
                  initialDate: selected,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) setState(() => selected = picked);
              },
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.isNotEmpty) {
                  context.read<SystemConfigCubit>().addHoliday(nameCtrl.text, selected);
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
