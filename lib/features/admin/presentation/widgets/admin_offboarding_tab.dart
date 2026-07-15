import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../bloc/offboarding_cubit.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/pulsing_pending_chip.dart';

class AdminOffboardingTab extends StatelessWidget {
  const AdminOffboardingTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<OffboardingCubit>()..fetchData(),
      child: BlocBuilder<OffboardingCubit, OffboardingState>(
        builder: (context, state) {
          if (state is OffboardingLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is OffboardingLoaded) {
            return _buildContent(context, state);
          } else if (state is OffboardingError) {
            return Center(
                child: Text(state.message,
                    style: const TextStyle(color: Colors.red)));
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, OffboardingLoaded state) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16.w),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showInitiateOffboardingDialog(context),
              icon: const Icon(Icons.person_remove),
              label: const Text('Initiate Offboarding'),
            ),
          ),
        ),
        Expanded(
          child: state.cases.isEmpty
              ? Center(
                  child: Text('No offboarding cases at the moment.',
                      style: TextStyle(color: AppColors.textSecondary)),
                )
              : ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  itemCount: state.cases.length,
                  itemBuilder: (context, index) {
                    final record = state.cases[index];
                    return AppCard(
                      margin: EdgeInsets.only(bottom: 12.h),
                      child: ExpansionTile(
                        title: Text(record.employeeName,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Last Day: ${record.lastWorkingDay}'),
                            SizedBox(height: 4.h),
                            Row(
                              children: [
                                record.status == 'inProgress'
                                  ? PulsingPendingChip(label: 'inProgress')
                                  : Chip(
                                      label: Text(
                                        record.status,
                                        style: const TextStyle(
                                            fontSize: 10, color: Colors.white),
                                      ),
                                      backgroundColor: record.status == 'completed'
                                          ? Colors.green
                                          : Colors.grey,
                                      visualDensity: VisualDensity.compact,
                                    ),
                              ],
                            ),
                            SizedBox(height: 8.h),
                            LinearProgressIndicator(
                              value: record.completionPercent,
                              color: AppColors.primary,
                              backgroundColor:
                                  AppColors.primary.withValues(alpha: 0.2),
                            ),
                          ],
                        ),
                        children: record.tasks
                            .map((t) => CheckboxListTile(
                                  title: Text(t.title),
                                  value: t.completed,
                                  activeColor: AppColors.primary,
                                  onChanged: (bool? value) {
                                    context
                                        .read<OffboardingCubit>()
                                        .toggleOffboardingTask(record.id, t.id);
                                  },
                                ))
                            .toList(),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showInitiateOffboardingDialog(BuildContext parentContext) {
    final nameCtrl = TextEditingController();
    final dateCtrl = TextEditingController();
    showDialog(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Initiate Offboarding'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Employee Name')),
            SizedBox(height: 12.h),
            TextField(
                controller: dateCtrl,
                decoration: const InputDecoration(
                    labelText: 'Last Working Day (YYYY-MM-DD)')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && dateCtrl.text.isNotEmpty) {
                parentContext
                    .read<OffboardingCubit>()
                    .initiateOffboarding(nameCtrl.text, dateCtrl.text);
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Initiate'),
          ),
        ],
      ),
    );
  }
}
