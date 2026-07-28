
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/localization/app_locals.dart';
import 'system_config_settings_card.dart';
import '../../../../core/widgets/web_shimmer_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:hr_core/features/admin/domain/entities/system_config_entities.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/bloc/web_cubits.dart';
import '../bloc/system_config_cubit.dart';

class BranchesContent extends StatelessWidget {
  const BranchesContent({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SystemConfigCubit, WebState<SystemConfigState>>(
      builder: (context, state) {
        if (state is WebSuccess<SystemConfigState>) {
          final branches = state.data.branches;
          return SettingsCard(
            title: AppLocals.officeBranches.tr(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppLocals.manageLocations.tr(), style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ElevatedButton.icon(
                      onPressed: () => _showBranchDialog(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(AppLocals.addBranch.tr()),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (branches.isEmpty)
                  Center(child: Padding(padding: const EdgeInsets.all(32), child: Text(AppLocals.noBranchesFound.tr(), style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))))
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: branches.length,
                    separatorBuilder: (_, __) => const Divider(height: 16),
                    itemBuilder: (context, index) {
                      final b = branches[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(b.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('${b.latitude}, ${b.longitude} • ${AppLocals.radius.tr()}: ${b.radiusMeters}m', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: b.isActive,
                              onChanged: (val) async {
                                try {
                                  await context.read<SystemConfigCubit>().updateBranch(b.copyWith(isActive: val));
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(val ? 'Branch activated' : 'Branch deactivated')),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                                    );
                                  }
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Iconsax.edit_2, size: 18),
                              onPressed: () => _showBranchDialog(context, branch: b),
                            ),
                            IconButton(
                              icon: Icon(Iconsax.trash, size: 18, color: AppColors.error),
                              onPressed: () async {
                                try {
                                  await context.read<SystemConfigCubit>().deleteBranch(b.id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Branch deleted successfully')),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                                    );
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        }
        if (state is WebError<SystemConfigState>) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(state.message, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.read<SystemConfigCubit>().load(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        return const ShimmerLoading();
      },
    );
  }

  void _showBranchDialog(BuildContext context, {OfficeBranch? branch}) {
    final nameCtrl = TextEditingController(text: branch?.name);
    final latCtrl = TextEditingController(text: branch?.latitude.toString());
    final lngCtrl = TextEditingController(text: branch?.longitude.toString());
    final radiusCtrl = TextEditingController(text: branch?.radiusMeters.toString() ?? '200');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(branch == null ? AppLocals.addBranch.tr() : AppLocals.editBranch.tr()),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(labelText: AppLocals.branchName.tr(), hintText: 'e.g. Cairo Main Branch'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: latCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      decoration: InputDecoration(labelText: AppLocals.latitude.tr(), hintText: 'e.g. 30.286884'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: lngCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      decoration: InputDecoration(labelText: AppLocals.longitude.tr(), hintText: 'e.g. 31.756905'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: radiusCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: AppLocals.allowedRadius.tr(), hintText: 'e.g. 200'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocals.cancel.tr())),
          FilledButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final lat = double.tryParse(latCtrl.text.trim());
              final lng = double.tryParse(lngCtrl.text.trim());
              final radius = int.tryParse(radiusCtrl.text.trim());

              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a branch name'), backgroundColor: Colors.orange),
                );
                return;
              }
              if (lat == null || lat < -90 || lat > 90) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Latitude must be a valid number between -90 and 90'), backgroundColor: Colors.orange),
                );
                return;
              }
              if (lng == null || lng < -180 || lng > 180) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Longitude must be a valid number between -180 and 180'), backgroundColor: Colors.orange),
                );
                return;
              }
              if (radius == null || radius < 10) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Allowed radius must be at least 10 meters'), backgroundColor: Colors.orange),
                );
                return;
              }

              final newBranch = OfficeBranch(
                id: branch?.id ?? '',
                name: name,
                latitude: lat,
                longitude: lng,
                radiusMeters: radius,
                isActive: branch?.isActive ?? true,
              );

              try {
                if (branch == null) {
                  await context.read<SystemConfigCubit>().addBranch(newBranch);
                } else {
                  await context.read<SystemConfigCubit>().updateBranch(newBranch);
                }
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(branch == null ? 'Branch added successfully' : 'Branch updated successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: Text(AppLocals.save.tr()),
          ),
        ],
      ),
    );
  }
}
