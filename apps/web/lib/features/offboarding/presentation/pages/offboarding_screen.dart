import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/bloc/web_cubits.dart';
import 'package:hr_core/features/admin/domain/entities/offboarding_entities.dart';
import 'package:hr_core/features/admin/domain/repositories/offboarding_repository.dart';
import '../../../../core/di/injection.dart';

class OffboardingCubit extends WebCubit<List<OffboardingCase>> {
  final OffboardingRepository _repo;
  OffboardingCubit(this._repo) : super(() => _repo.getOffboardingCases());

  Future<void> toggleTask(String caseId, String taskId) async {
    await _repo.toggleOffboardingTask(caseId, taskId);
    load();
  }
}

class OffboardingScreen extends StatelessWidget {
  const OffboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OffboardingCubit(getIt<OffboardingRepository>()),
      child: const _OffboardingView(),
    );
  }
}

class _OffboardingView extends StatefulWidget {
  const _OffboardingView();
  @override
  State<_OffboardingView> createState() => _OffboardingViewState();
}

class _OffboardingViewState extends State<_OffboardingView> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _slideAnimation = Tween<Offset>(begin: const Offset(0.08, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _fadeAnimation = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _select(int i) {
    if (i == _selectedIndex) return;
    setState(() => _selectedIndex = i);
    _slideController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    const exitColor = Color(0xFFEF4444);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Offboarding Tracking', style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 24),
            Expanded(
              child: BlocBuilder<OffboardingCubit, WebState<List<OffboardingCase>>>(
                builder: (context, state) {
                  if (state is WebLoading || state is WebInitial) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is WebError<List<OffboardingCase>>) {
                    return Center(child: Text('Error: ${state.message}'));
                  }
                  if (state is WebSuccess<List<OffboardingCase>>) {
                    final leavers = state.data;
                    if (leavers.isEmpty) {
                      return const Center(child: Text('No offboarding records found.'));
                    }
                    if (_selectedIndex >= leavers.length) {
                      _selectedIndex = 0;
                    }
                    final leaver = leavers[_selectedIndex];

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
                              boxShadow: [BoxShadow(color: exitColor.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 6))],
                            ),
                            child: ListView.separated(
                              padding: const EdgeInsets.all(12),
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemCount: leavers.length,
                              itemBuilder: (context, i) {
                                final e = leavers[i];
                                final isSelected = i == _selectedIndex;
                                final completed = e.tasks.where((t) => t.completed).length;
                                final total = e.tasks.length;
                                return InkWell(
                                  onTap: () => _select(i),
                                  borderRadius: BorderRadius.circular(12),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: isSelected ? exitColor.withValues(alpha: 0.06) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: isSelected ? exitColor.withValues(alpha: 0.3) : Colors.transparent),
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundColor: exitColor.withValues(alpha: 0.1),
                                          child: Text(e.employeeName[0], style: const TextStyle(color: exitColor, fontWeight: FontWeight.bold)),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(e.employeeName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                              const SizedBox(height: 2),
                                              Text('Status: ${e.status}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                              const SizedBox(height: 8),
                                              Row(children: [
                                                Expanded(child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(3),
                                                  child: LinearProgressIndicator(
                                                    value: total == 0 ? 0 : completed / total,
                                                    minHeight: 5,
                                                    backgroundColor: exitColor.withValues(alpha: 0.1),
                                                    valueColor: const AlwaysStoppedAnimation<Color>(exitColor),
                                                  ),
                                                )),
                                                const SizedBox(width: 8),
                                                Text('$completed/$total', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                              ]),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          flex: 3,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: Container(
                                padding: const EdgeInsets.all(28),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
                                  boxShadow: [BoxShadow(color: exitColor.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 6))],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      CircleAvatar(
                                        radius: 28,
                                        backgroundColor: exitColor.withValues(alpha: 0.1),
                                        child: Text(leaver.employeeName[0], style: const TextStyle(color: exitColor, fontSize: 22, fontWeight: FontWeight.bold)),
                                      ),
                                      const SizedBox(width: 16),
                                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Text(leaver.employeeName, style: Theme.of(context).textTheme.headlineSmall),
                                        Text('Status: ${leaver.status}', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                        const SizedBox(height: 4),
                                        Row(children: [
                                          const Icon(Iconsax.calendar_remove, size: 13, color: exitColor),
                                          const SizedBox(width: 4),
                                          Text('Last day: ${leaver.lastWorkingDay}', style: const TextStyle(color: exitColor, fontSize: 12, fontWeight: FontWeight.w500)),
                                        ]),
                                      ]),
                                    ]),
                                    const SizedBox(height: 32),
                                    Text('Offboarding Checklist', style: Theme.of(context).textTheme.titleMedium),
                                    const SizedBox(height: 16),
                                    ...leaver.tasks.map((task) => InkWell(
                                      onTap: () => context.read<OffboardingCubit>().toggleTask(leaver.id, task.id),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        child: Row(children: [
                                          AnimatedSwitcher(
                                            duration: const Duration(milliseconds: 200),
                                            child: Icon(
                                              task.completed ? Iconsax.tick_circle_copy : Iconsax.record_circle,
                                              key: ValueKey(task.completed),
                                              color: task.completed ? exitColor : Colors.grey,
                                              size: 22,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(task.title, style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: task.completed ? FontWeight.normal : FontWeight.w500,
                                            decoration: task.completed ? TextDecoration.lineThrough : null,
                                            color: task.completed ? Colors.grey : null,
                                          )),
                                        ]),
                                      ),
                                    )),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
