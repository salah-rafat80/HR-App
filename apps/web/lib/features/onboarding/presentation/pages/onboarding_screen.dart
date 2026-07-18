import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/bloc/web_cubits.dart';
import 'package:hr_core/features/admin/domain/entities/recruitment_entities.dart';
import 'package:hr_core/features/admin/domain/repositories/recruitment_repository.dart';
import '../../../../core/di/injection.dart';

class OnboardingCubit extends WebCubit<List<NewHireOnboarding>> {
  final RecruitmentRepository _repo;
  OnboardingCubit(this._repo) : super(() => _repo.getOnboardingRecords());

  Future<void> toggleTask(String recordId, String taskId) async {
    await _repo.toggleOnboardingTask(recordId, taskId);
    load();
  }
}

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OnboardingCubit(getIt<RecruitmentRepository>()),
      child: const _OnboardingView(),
    );
  }
}

class _OnboardingView extends StatefulWidget {
  const _OnboardingView();
  @override
  State<_OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<_OnboardingView> with SingleTickerProviderStateMixin {
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

  void _selectEmployee(int i) {
    if (i == _selectedIndex) return;
    setState(() => _selectedIndex = i);
    _slideController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Onboarding Tracking', style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 24),
            Expanded(
              child: BlocBuilder<OnboardingCubit, WebState<List<NewHireOnboarding>>>(
                builder: (context, state) {
                  if (state is WebLoading || state is WebInitial) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is WebError<List<NewHireOnboarding>>) {
                    return Center(child: Text('Error: ${state.message}'));
                  }
                  if (state is WebSuccess<List<NewHireOnboarding>>) {
                    final employees = state.data;
                    if (employees.isEmpty) {
                      return const Center(child: Text('No onboarding records found.'));
                    }
                    if (_selectedIndex >= employees.length) {
                      _selectedIndex = 0;
                    }
                    final emp = employees[_selectedIndex];
                    
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // List panel
                        Expanded(
                          flex: 2,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
                              boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 6))],
                            ),
                            child: ListView.separated(
                              padding: const EdgeInsets.all(12),
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemCount: employees.length,
                              itemBuilder: (context, i) {
                                final e = employees[i];
                                final isSelected = i == _selectedIndex;
                                final completed = e.tasks.where((t) => t.completed).length;
                                final total = e.tasks.length;
                                
                                return InkWell(
                                  onTap: () => _selectEmployee(i),
                                  borderRadius: BorderRadius.circular(12),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: isSelected ? AppColors.primary.withValues(alpha: 0.3) : Colors.transparent),
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                          child: Text(e.hireName[0], style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(e.hireName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                              const SizedBox(height: 2),
                                              Text('Starts: ${e.startDate}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                              const SizedBox(height: 8),
                                              Row(children: [
                                                Expanded(child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(3),
                                                  child: LinearProgressIndicator(
                                                    value: total == 0 ? 0 : completed / total,
                                                    minHeight: 5,
                                                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
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
                        // Detail panel with slide animation
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
                                  boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 6))],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 28,
                                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                          child: Text(emp.hireName[0], style: TextStyle(color: AppColors.primary, fontSize: 22, fontWeight: FontWeight.bold)),
                                        ),
                                        const SizedBox(width: 16),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(emp.hireName, style: Theme.of(context).textTheme.headlineSmall),
                                            const SizedBox(height: 4),
                                            Row(children: [
                                              const Icon(Iconsax.clock, size: 13, color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Text('Starts: ${emp.startDate}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                            ]),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 32),
                                    Text('Onboarding Checklist', style: Theme.of(context).textTheme.titleMedium),
                                    const SizedBox(height: 16),
                                    ...emp.tasks.map((task) => InkWell(
                                      onTap: () => context.read<OnboardingCubit>().toggleTask(emp.id, task.id),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        child: Row(
                                          children: [
                                            AnimatedSwitcher(
                                              duration: const Duration(milliseconds: 200),
                                              child: Icon(
                                                task.completed ? Iconsax.tick_circle_copy : Iconsax.record_circle,
                                                key: ValueKey(task.completed),
                                                color: task.completed ? AppColors.primary : Colors.grey,
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
                                          ],
                                        ),
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
