import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../bloc/system_config_cubit.dart';
import '../../../../core/bloc/session_cubit.dart';
import '../../../../core/enums/role_enums.dart';
import '../../domain/entities/system_config_entities.dart';

class AdminSystemConfigTab extends StatelessWidget {
  const AdminSystemConfigTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SystemConfigCubit>()..fetchData(),
      child: BlocBuilder<SystemConfigCubit, SystemConfigState>(
        builder: (context, state) {
          if (state is SystemConfigLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is SystemConfigLoaded) {
            final isSuperAdmin = getIt<SessionCubit>().state == UserRole.superAdmin;
            
            return SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isSuperAdmin) ...[
                    _buildSectionHeader('Roles & Permissions'),
                    ...state.rolePermissions.map((p) => SwitchListTile(
                          title: Text('${p.role.name.toUpperCase()} - ${p.featureKey}'),
                          value: p.allowed,
                          onChanged: (_) => context.read<SystemConfigCubit>().toggleRolePermission(p.role, p.featureKey),
                        )),
                    const Divider(),
                    SizedBox(height: 16.h),

                    _buildSectionHeader('Company Settings'),
                    if (state.companySettings != null)
                      ListTile(
                        title: Text(state.companySettings!.companyName),
                        subtitle: Text('${state.companySettings!.timezoneLabel} • ${state.companySettings!.workWeekDays.join(", ")}'),
                        trailing: ElevatedButton(
                          onPressed: () => _editCompanySettings(context, state.companySettings!),
                          child: const Text('Edit'),
                        ),
                      ),
                    const Divider(),
                    SizedBox(height: 16.h),

                    _buildSectionHeader('Integrations'),
                    ...state.integrations.map((i) => SwitchListTile(
                          title: Text(i.name),
                          value: i.enabled,
                          onChanged: (_) => context.read<SystemConfigCubit>().toggleIntegration(i.name),
                        )),
                    const Divider(),
                    SizedBox(height: 16.h),
                  ],

                  _buildSectionHeader('Leave Types & Allowances'),
                  ...state.leaveTypes.map((l) => ListTile(
                        title: Text(l.type.name.toUpperCase()),
                        trailing: Text('${l.defaultDaysPerYear} days', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
                        onTap: () => _editLeaveDays(context, l),
                      )),
                  const Divider(),
                  SizedBox(height: 16.h),
                  
                  _buildSectionHeader('Holiday Calendar'),
                  ElevatedButton.icon(
                    onPressed: () => _addHoliday(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Holiday'),
                  ),
                  ...state.holidays.map((h) => ListTile(
                        title: Text(h.name),
                        trailing: Text('${h.date.day}/${h.date.month}/${h.date.year}'),
                      )),
                  const Divider(),
                  SizedBox(height: 16.h),
                  
                  _buildSectionHeader('Departments'),
                  ElevatedButton.icon(
                    onPressed: () => _addDepartment(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Department'),
                  ),
                  ...state.departments.map((d) => ListTile(
                        title: Text(d.name),
                        trailing: Text('${d.headcount} employees'),
                      )),
                  const Divider(),
                  SizedBox(height: 16.h),

                  _buildSectionHeader('Appraisal Settings'),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      onPressed: () => _startAppraisalCycle(context),
                      icon: const Icon(Icons.flag),
                      label: const Text('Start New Appraisal Cycle'),
                    ),
                  ),
                  SizedBox(height: 40.h),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(title, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: AppColors.primary)),
    );
  }

  void _editLeaveDays(BuildContext context, dynamic leaveTypeConfig) {
    final ctrl = TextEditingController(text: leaveTypeConfig.defaultDaysPerYear.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit ${leaveTypeConfig.type.name} Days'),
        content: TextField(controller: ctrl, keyboardType: TextInputType.number),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final days = int.tryParse(ctrl.text) ?? 0;
              context.read<SystemConfigCubit>().updateLeaveDays(leaveTypeConfig.type, days);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _addHoliday(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Holiday'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Holiday Name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.isNotEmpty) {
                context.read<SystemConfigCubit>().addHoliday(ctrl.text, DateTime.now().add(const Duration(days: 30)));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _addDepartment(BuildContext context) {
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

  void _startAppraisalCycle(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Start New Appraisal Cycle'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Cycle Label (e.g. Q3 2026)')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.isNotEmpty) {
                context.read<SystemConfigCubit>().startNewAppraisalCycle(ctrl.text, DateTime.now().add(const Duration(days: 90)));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Appraisal Cycle Started!')));
              }
            },
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }

  void _editCompanySettings(BuildContext context, CompanySettings current) {
    final nameCtrl = TextEditingController(text: current.companyName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Company Settings'),
        content: TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Company Name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                final updated = current.copyWith(companyName: nameCtrl.text);
                context.read<SystemConfigCubit>().updateCompanySettings(updated);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings Saved')));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
