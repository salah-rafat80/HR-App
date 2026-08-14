import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hr_core/core/enums/role_enums.dart';
import 'package:hr_core/features/admin/domain/repositories/system_config_repository.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/bloc/session_cubit.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/app_locals.dart';
import '../bloc/system_config_cubit.dart';
import '../widgets/system_config_leave_types.dart';
import '../widgets/system_config_holidays.dart';
import '../widgets/system_config_departments.dart';
import '../widgets/system_config_roles.dart';
import '../widgets/system_config_company.dart';
import '../widgets/system_config_integrations.dart';
import '../widgets/system_config_branches.dart';

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
    final sessionState = context.read<SessionCubit>().state;
    final isSuperAdmin = sessionState.role == UserRole.superAdmin;

    final tabs = <_TabDef>[
      _TabDef('Leave Types', Iconsax.calendar_2),
      _TabDef('Holidays', Iconsax.sun),
      _TabDef('Departments', Iconsax.buildings),
      if (isSuperAdmin) _TabDef('Roles & Permissions', Iconsax.lock),
      if (isSuperAdmin) _TabDef('Company Settings', Iconsax.building),
      if (isSuperAdmin) _TabDef(AppLocals.officeBranches.tr(), Iconsax.map),
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
      _ContentDef('Leave Types', Iconsax.calendar_2, (ctx) => const LeaveTypesContent()),
      _ContentDef('Holidays', Iconsax.sun, (ctx) => const HolidaysContent()),
      _ContentDef('Departments', Iconsax.buildings, (ctx) => const DepartmentsContent()),
      if (isSuperAdmin) _ContentDef('Roles & Permissions', Iconsax.lock, (ctx) => const RolesContent()),
      if (isSuperAdmin) _ContentDef('Company Settings', Iconsax.building, (ctx) => const CompanyContent()),
      if (isSuperAdmin) _ContentDef(AppLocals.officeBranches.tr(), Iconsax.map, (ctx) => const BranchesContent()),
      if (isSuperAdmin) _ContentDef('Integrations', Iconsax.cpu, (ctx) => const IntegrationsContent()),
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




















