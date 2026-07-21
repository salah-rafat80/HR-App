import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hr_core/core/enums/role_enums.dart';
import 'package:hr_core/features/admin/domain/entities/system_config_entities.dart';
import 'package:hr_core/features/admin/domain/repositories/system_config_repository.dart';
import 'package:hr_core/features/leave/domain/entities/leave_enums.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../core/bloc/session_cubit.dart';
import '../../../../core/bloc/web_cubits.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/system_config_cubit.dart';

class SystemConfigScreen extends StatelessWidget {
  const SystemConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SystemConfigCubit(getIt<SystemConfigRepository>()),
      child: const _SystemConfigView(),
    );
  }
}

class _SystemConfigView extends StatefulWidget {
  const _SystemConfigView();

  @override
  State<_SystemConfigView> createState() => _SystemConfigViewState();
}

class _SystemConfigViewState extends State<_SystemConfigView> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _contentController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _contentController = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _contentController, curve: Curves.easeOut));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(CurvedAnimation(parent: _contentController, curve: Curves.easeOut));
    _contentController.forward();
  }

  @override
  void dispose() { _contentController.dispose(); super.dispose(); }

  void _selectTab(int i) {
    if (i == _selectedIndex) return;
    setState(() => _selectedIndex = i);
    _contentController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final role = context.read<SessionCubit>().state;
    final isSuperAdmin = role == UserRole.superAdmin;

    final tabs = <_TabDef>[
      _TabDef('Leave Types', Iconsax.calendar_2),
      _TabDef('Holidays', Iconsax.sun),
      _TabDef('Departments', Iconsax.buildings),
      if (isSuperAdmin) _TabDef('Roles & Permissions', Iconsax.lock),
      if (isSuperAdmin) _TabDef('Company Settings', Iconsax.building),
      if (isSuperAdmin) _TabDef('Integrations', Iconsax.cpu),
    ];

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 240,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              border: Border(right: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text('Configuration', style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant, letterSpacing: 1)),
                ),
                ...List.generate(tabs.length, (i) => _buildTabItem(tabs[i], i, i == _selectedIndex)),
              ],
            ),
          ),
          Expanded(
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildContent(isSuperAdmin),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(_TabDef tab, int i, bool isSelected) {
    return InkWell(
      onTap: () => _selectTab(i),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? AppColors.primary.withValues(alpha: 0.3) : Colors.transparent),
        ),
        child: Row(children: [
          Icon(tab.icon, size: 18, color: isSelected ? AppColors.primary : Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Text(tab.title, style: TextStyle(fontSize: 14, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? AppColors.primary : Theme.of(context).colorScheme.onSurface)),
        ]),
      ),
    );
  }

  Widget _buildContent(bool isSuperAdmin) {
    final allContent = <_ContentDef>[
      _ContentDef('Leave Types', Iconsax.calendar_2, (ctx) => const _LeaveTypesContent()),
      _ContentDef('Holidays', Iconsax.sun, (ctx) => const _HolidaysContent()),
      _ContentDef('Departments', Iconsax.buildings, (ctx) => const _DepartmentsContent()),
      if (isSuperAdmin) _ContentDef('Roles & Permissions', Iconsax.lock, (ctx) => const _RolesContent()),
      if (isSuperAdmin) _ContentDef('Company Settings', Iconsax.building, (ctx) => const _CompanyContent()),
      if (isSuperAdmin) _ContentDef('Integrations', Iconsax.cpu, (ctx) => const _IntegrationsContent()),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(allContent[_selectedIndex].icon, size: 22, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(allContent[_selectedIndex].title, style: Theme.of(context).textTheme.displaySmall),
          ]),
          const SizedBox(height: 24),
          allContent[_selectedIndex].builder(context),
        ],
      ),
    );
  }
}

class _TabDef {
  final String title;
  final IconData icon;
  const _TabDef(this.title, this.icon);
}

class _ContentDef {
  final String title;
  final IconData icon;
  final Widget Function(BuildContext) builder;
  const _ContentDef(this.title, this.icon, this.builder);
}

class _ShimmerLoading extends StatelessWidget {
  const _ShimmerLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _LeaveTypesContent extends StatelessWidget {
  const _LeaveTypesContent();

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
          return _SettingsCard(title: 'Configured Leave Types', child: Column(children: [
            ...types.map((t) => _LeaveTypeRow(type: t, color: _colorFor(t.type), label: _labelFor(t.type))),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Iconsax.add, size: 16),
              label: const Text('Add Leave Type'),
              onPressed: () {},
            ),
          ]));
        }
        return const _ShimmerLoading();
      },
    );
  }
}

class _LeaveTypeRow extends StatelessWidget {
  final LeaveTypeConfig type;
  final Color color;
  final String label;
  const _LeaveTypeRow({required this.type, required this.color, required this.label});

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

class _HolidaysContent extends StatelessWidget {
  const _HolidaysContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SystemConfigCubit, WebState<SystemConfigState>>(
      builder: (context, state) {
        if (state is WebSuccess<SystemConfigState>) {
          final holidays = state.data.holidays;
          return _SettingsCard(title: 'Public Holidays', child: Column(children: [
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
        return const _ShimmerLoading();
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

class _DepartmentsContent extends StatelessWidget {
  const _DepartmentsContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SystemConfigCubit, WebState<SystemConfigState>>(
      builder: (context, state) {
        if (state is WebSuccess<SystemConfigState>) {
          final depts = state.data.departments;
          return _SettingsCard(title: 'Departments', child: Column(children: [
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
        return const _ShimmerLoading();
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

class _RolesContent extends StatelessWidget {
  const _RolesContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SystemConfigCubit, WebState<SystemConfigState>>(
      builder: (context, state) {
        if (state is WebSuccess<SystemConfigState>) {
          final perms = state.data.rolePermissions;
          return _SettingsCard(title: 'Role & Permission Matrix', child: Column(children: [
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
        return const _ShimmerLoading();
      },
    );
  }
}

class _CompanyContent extends StatelessWidget {
  const _CompanyContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SystemConfigCubit, WebState<SystemConfigState>>(
      builder: (context, state) {
        if (state is WebSuccess<SystemConfigState>) {
          final settings = state.data.companySettings;
          final nameCtrl = TextEditingController(text: settings.companyName);
          final tzCtrl = TextEditingController(text: settings.timezoneLabel);
          return _SettingsCard(title: 'Company Profile', child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Company Name')),
            const SizedBox(height: 16),
            Text('Work Week: ${settings.workWeekDays.join(", ")}', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(controller: tzCtrl, decoration: const InputDecoration(labelText: 'Timezone')),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.read<SystemConfigCubit>().updateCompanySettings(
                  settings.copyWith(companyName: nameCtrl.text, timezoneLabel: tzCtrl.text),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Company settings saved')),
                );
              },
              child: const Text('Save Changes'),
            ),
          ]));
        }
        return const _ShimmerLoading();
      },
    );
  }
}

class _IntegrationsContent extends StatelessWidget {
  const _IntegrationsContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SystemConfigCubit, WebState<SystemConfigState>>(
      builder: (context, state) {
        if (state is WebSuccess<SystemConfigState>) {
          final integrations = state.data.integrations;
          return _SettingsCard(title: 'Connected Integrations', child: Column(children: [
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
        return const _ShimmerLoading();
      },
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SettingsCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const Divider(height: 28),
        child,
      ]),
    );
  }
}
