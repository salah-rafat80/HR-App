
import 'system_config_settings_card.dart';
import '../../../../core/widgets/web_shimmer_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/bloc/web_cubits.dart';
import '../bloc/system_config_cubit.dart';

class IntegrationsContent extends StatelessWidget {
  const IntegrationsContent({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SystemConfigCubit, WebState<SystemConfigState>>(
      builder: (context, state) {
        if (state is WebSuccess<SystemConfigState>) {
          final integrations = state.data.integrations;
          return SettingsCard(title: 'Connected Integrations', child: Column(children: [
            ...integrations.map((i) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(children: [
                Icon(i.enabled ? Iconsax.tick_circle : Iconsax.slash, size: 18, color: i.enabled ? Colors.green : Colors.grey),
                const SizedBox(width: 12),
                Expanded(child: Text(i.name, style: const TextStyle(fontWeight: FontWeight.w500))),
                Switch(
                  value: i.enabled,
                  onChanged: (_) => context.read<SystemConfigCubit>().toggleIntegration(i.name),
                  activeColor: AppColors.primary,
                ),
              ]),
            )),
          ]));
        }
        if (state is WebError<SystemConfigState>) return Center(child: Text(state.message, style: const TextStyle(color: Colors.red))); return const ShimmerLoading();
      },
    );
  }
}
