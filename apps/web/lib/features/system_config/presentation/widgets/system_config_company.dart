
import 'system_config_settings_card.dart';
import '../../../../core/widgets/web_shimmer_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/bloc/web_cubits.dart';
import '../bloc/system_config_cubit.dart';

class CompanyContent extends StatelessWidget {
  const CompanyContent({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SystemConfigCubit, WebState<SystemConfigState>>(
      builder: (context, state) {
        if (state is WebSuccess<SystemConfigState>) {
          final settings = state.data.companySettings;
          final nameCtrl = TextEditingController(text: settings.companyName);
          final tzCtrl = TextEditingController(text: settings.timezoneLabel);
          
          return SettingsCard(title: 'Company Profile', child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Company Name')),
            const SizedBox(height: 16),
            Text('Work Week: ${settings.workWeekDays.join(", ")}', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(controller: tzCtrl, decoration: const InputDecoration(labelText: 'Timezone')),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.read<SystemConfigCubit>().updateCompanySettings(
                  settings.copyWith(
                    companyName: nameCtrl.text,
                    timezoneLabel: tzCtrl.text,
                  ),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Company settings saved')),
                );
              },
              child: const Text('Save Changes'),
            ),
          ]));
        }
        if (state is WebError<SystemConfigState>) return Center(child: Text(state.message, style: const TextStyle(color: Colors.red))); return const ShimmerLoading();
      },
    );
  }
}
