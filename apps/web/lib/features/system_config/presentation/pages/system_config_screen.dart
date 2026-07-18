import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hr_core/core/enums/role_enums.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../core/bloc/session_cubit.dart';
import '../../../../core/theme/app_colors.dart';

class SystemConfigScreen extends StatefulWidget {
  const SystemConfigScreen({super.key});
  @override
  State<SystemConfigScreen> createState() => _SystemConfigScreenState();
}

class _SystemConfigScreenState extends State<SystemConfigScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late List<AnimationController> _controllers;
  late AnimationController _contentController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  late List<_ConfigSection> _sections;

  @override
  void initState() {
    super.initState();
    _contentController = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _contentController, curve: Curves.easeOut));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(CurvedAnimation(parent: _contentController, curve: Curves.easeOut));
    _contentController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final role = context.read<SessionCubit>().state;
    final isSuperAdmin = role == UserRole.superAdmin;

    _sections = [
      _ConfigSection('Leave Types', Iconsax.calendar_2, _buildLeaveTypeSettings),
      _ConfigSection('Holidays', Iconsax.sun, _buildHolidaySettings),
      _ConfigSection('Departments', Iconsax.buildings, _buildDeptSettings),
      if (isSuperAdmin) _ConfigSection('Roles & Permissions', Iconsax.lock, _buildRolesSettings),
      if (isSuperAdmin) _ConfigSection('Company Settings', Iconsax.building, _buildCompanySettings),
      if (isSuperAdmin) _ConfigSection('Integrations', Iconsax.cpu, _buildIntegrationsSettings),
    ];

    _controllers = List.generate(_sections.length, (_) => AnimationController(vsync: this, duration: const Duration(milliseconds: 200)));
  }

  @override
  void dispose() {
    for (final c in _controllers) { c.dispose(); }
    _contentController.dispose();
    super.dispose();
  }

  void _selectTab(int i) {
    if (i == _selectedIndex) return;
    setState(() => _selectedIndex = i);
    _contentController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Tab sidebar
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
                  child: Text('Configuration', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant, letterSpacing: 1)),
                ),
                ...List.generate(_sections.length, (i) => _buildTabItem(_sections[i], i)),
              ],
            ),
          ),
          // Content area
          Expanded(
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(_sections[_selectedIndex].icon, size: 22, color: AppColors.primary),
                          const SizedBox(width: 12),
                          Text(_sections[_selectedIndex].title, style: Theme.of(context).textTheme.displaySmall),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _sections[_selectedIndex].contentBuilder(context),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(_ConfigSection section, int i) {
    final isSelected = i == _selectedIndex;
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
        child: Row(
          children: [
            Icon(isSelected ? section.icon : section.icon, size: 18, color: isSelected ? AppColors.primary : Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Text(section.title, style: TextStyle(fontSize: 14, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal, color: isSelected ? AppColors.primary : Theme.of(context).colorScheme.onSurface)),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaveTypeSettings(BuildContext context) {
    return _SettingsCard(
      title: 'Configured Leave Types',
      child: Column(children: [
        _buildLeaveTypeRow('Annual Leave', '21 days/year', const Color(0xFF22C55E)),
        _buildLeaveTypeRow('Sick Leave', '10 days/year', const Color(0xFF3B82F6)),
        _buildLeaveTypeRow('Unpaid Leave', 'Unlimited', const Color(0xFFF59E0B)),
        _buildLeaveTypeRow('Maternity Leave', '90 days', const Color(0xFF8B5CF6)),
        const SizedBox(height: 16),
        OutlinedButton.icon(icon: const Icon(Iconsax.add, size: 16), label: const Text('Add Leave Type'), onPressed: () {}),
      ]),
    );
  }

  Widget _buildLeaveTypeRow(String name, String quota, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 12),
        Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w500))),
        Text(quota, style: const TextStyle(color: Colors.grey)),
        const SizedBox(width: 16),
        const Icon(Iconsax.edit_2, size: 16, color: Colors.grey),
      ]),
    );
  }

  Widget _buildHolidaySettings(BuildContext context) {
    return _SettingsCard(
      title: 'Public Holidays 2026',
      child: Column(
        children: ['New Year (Jan 1)', 'National Day (Jul 23)', 'Eid Al-Adha (Jun 16-18)', 'Eid Al-Fitr (Apr 2-4)'].map((h) =>
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(children: [
              const Icon(Iconsax.star, size: 16, color: Color(0xFFF59E0B)),
              const SizedBox(width: 12),
              Expanded(child: Text(h, style: const TextStyle(fontWeight: FontWeight.w500))),
              const Icon(Iconsax.trash, size: 16, color: Colors.grey),
            ]),
          ),
        ).toList(),
      ),
    );
  }

  Widget _buildDeptSettings(BuildContext context) {
    return _SettingsCard(
      title: 'Departments',
      child: Column(
        children: [
          ...['Engineering', 'Sales', 'HR', 'Finance', 'Operations'].map((d) =>
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(children: [
                Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)), child: Icon(Iconsax.buildings, size: 14, color: AppColors.primary)),
                const SizedBox(width: 12),
                Expanded(child: Text(d, style: const TextStyle(fontWeight: FontWeight.w500))),
                const Icon(Iconsax.edit_2, size: 16, color: Colors.grey),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRolesSettings(BuildContext context) {
    return const _SettingsCard(title: 'Role & Permission Matrix', child: Text('Configure granular permissions per role across all modules.', style: TextStyle(color: Colors.grey)));
  }

  Widget _buildCompanySettings(BuildContext context) {
    return _SettingsCard(
      title: 'Company Profile',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const TextField(decoration: InputDecoration(labelText: 'Company Name')),
        const SizedBox(height: 16),
        const TextField(decoration: InputDecoration(labelText: 'Fiscal Year Start (e.g. Jan)')),
        const SizedBox(height: 16),
        const TextField(decoration: InputDecoration(labelText: 'Default Timezone')),
        const SizedBox(height: 24),
        ElevatedButton(onPressed: () {}, child: const Text('Save Changes')),
      ]),
    );
  }

  Widget _buildIntegrationsSettings(BuildContext context) {
    return _SettingsCard(
      title: 'Connected Integrations',
      child: Column(children: [
        _buildIntegrationRow('Slack', true),
        _buildIntegrationRow('Google Workspace', true),
        _buildIntegrationRow('JIRA', false),
        _buildIntegrationRow('Payroll Gateway', false),
      ]),
    );
  }

  Widget _buildIntegrationRow(String name, bool connected) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: [
        const Icon(Iconsax.cpu, size: 18),
        const SizedBox(width: 12),
        Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w500))),
        Switch(value: connected, onChanged: (v) {}, activeColor: AppColors.primary),
      ]),
    );
  }
}

class _ConfigSection {
  final String title;
  final IconData icon;
  final Widget Function(BuildContext) contentBuilder;
  const _ConfigSection(this.title, this.icon, this.contentBuilder);
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
