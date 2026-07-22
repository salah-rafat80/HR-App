import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hr_core/features/appraisal/domain/entities/appraisal_entities.dart';
import 'package:hr_core/features/appraisal/domain/repositories/appraisal_repository.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../core/bloc/web_cubits.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/appraisal_cubit.dart';

class AppraisalScreen extends StatelessWidget {
  const AppraisalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AppraisalCubit(getIt<AppraisalRepository>()),
      child: const _AppraisalView(),
    );
  }
}

class _AppraisalView extends StatelessWidget {
  const _AppraisalView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Iconsax.star, size: 32, color: Colors.teal),
                SizedBox(width: 16),
                Text('Appraisal Cycles', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 24),
            BlocBuilder<AppraisalCubit, WebState<AppraisalCycle>>(
              builder: (context, state) {
                if (state is WebLoading || state is WebInitial) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is WebError<AppraisalCycle>) {
                  return Center(child: Column(children: [
                    const Icon(Iconsax.warning_2, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: ${state.message}'),
                  ]));
                }
                if (state is WebSuccess<AppraisalCycle>) {
                  return _AppraisalBody(cycle: state.data);
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AppraisalBody extends StatelessWidget {
  final AppraisalCycle cycle;
  const _AppraisalBody({required this.cycle});

  Color _statusColor(AppraisalStatus status) {
    switch (status) {
      case AppraisalStatus.upcoming: return Colors.blue;
      case AppraisalStatus.inProgress: return Colors.orange;
      case AppraisalStatus.completed: return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SettingsCard(
          title: 'Current Cycle',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _statusColor(cycle.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    cycle.status.name.toUpperCase(),
                    style: TextStyle(color: _statusColor(cycle.status), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 12),
                Text(cycle.cycleLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                const Icon(Iconsax.calendar, size: 14, color: Colors.grey),
                const SizedBox(width: 8),
                Text('Due: ${cycle.dueDate.day}/${cycle.dueDate.month}/${cycle.dueDate.year}', style: const TextStyle(color: Colors.grey)),
                if (cycle.selfAppraisalSubmitted) ...[
                  const SizedBox(width: 16),
                  const Icon(Iconsax.tick_circle, size: 14, color: Colors.green),
                  const SizedBox(width: 4),
                  const Text('Self Appraisal Submitted', style: TextStyle(color: Colors.green, fontSize: 12)),
                ],
              ]),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _SettingsCard(
          title: 'Start New Cycle',
          child: _StartCycleForm(),
        ),
      ],
    );
  }
}

class _StartCycleForm extends StatefulWidget {
  const _StartCycleForm();

  @override
  State<_StartCycleForm> createState() => _StartCycleFormState();
}

class _StartCycleFormState extends State<_StartCycleForm> {
  final _labelCtrl = TextEditingController();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 90));
  bool _isSubmitting = false;

  @override
  void dispose() { _labelCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _labelCtrl,
          decoration: const InputDecoration(
            labelText: 'Cycle Label',
            hintText: 'e.g. Q3 2026 Review',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _dueDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 730)),
                );
                if (picked != null) setState(() => _dueDate = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Due Date',
                  border: OutlineInputBorder(),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${_dueDate.day}/${_dueDate.month}/${_dueDate.year}'),
                    const Icon(Iconsax.calendar, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        TextField(
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Instructions for Managers',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _doSubmit,
            child: _isSubmitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Initialize Cycle'),
          ),
        ),
      ],
    );
  }

  Future<void> _doSubmit() async {
    if (_labelCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a cycle label')),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    await context.read<AppraisalCubit>().startNewCycle(_labelCtrl.text, _dueDate);
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    _labelCtrl.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cycle created successfully')),
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
