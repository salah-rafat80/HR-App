import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/bloc/session_cubit.dart';
import '../../../../core/enums/role_enums.dart';
import '../../../../core/di/injection.dart';
import '../../domain/entities/team_member.dart';
import '../../../kpi/domain/entities/kpi_entities.dart';
import '../bloc/team_kpi_cubit.dart';

class TeamKpiOverviewTab extends StatelessWidget {
  const TeamKpiOverviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final role = getIt<SessionCubit>().state;
        final scope = role == UserRole.manager ? ApprovalScope.department : ApprovalScope.team;
        return getIt<TeamKpiCubit>()..fetchTeamKpis(scope);
      },
      child: BlocBuilder<TeamKpiCubit, TeamKpiState>(
        builder: (context, state) {
          if (state is TeamKpiLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is TeamKpiLoaded) {
            return _buildList(context, state.members);
          } else if (state is TeamKpiError) {
            return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildList(BuildContext context, List<TeamMember> members) {
    if (members.isEmpty) {
      return Center(
        child: Text('No team members found.', style: TextStyle(color: AppColors.textSecondary, fontSize: 16.sp)),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        return Card(
          margin: EdgeInsets.only(bottom: 12.h),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(member.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
                    _buildStatusChip(member.leaveStatus),
                  ],
                ),
                SizedBox(height: 4.h),
                Text('${member.title} • ${member.department}', style: TextStyle(color: AppColors.textSecondary)),
                SizedBox(height: 16.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('KPI Progress', style: TextStyle(fontSize: 14.sp)),
                    Text('${(member.kpiScorePercent * 100).toInt()}%', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ],
                ),
                SizedBox(height: 8.h),
                LinearProgressIndicator(
                  value: member.kpiScorePercent,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                  color: AppColors.primary,
                ),
                SizedBox(height: 12.h),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _showAssignKpiDialog(context, member),
                    icon: const Icon(Icons.add_task),
                    label: const Text('Assign KPI'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;
    switch (status) {
      case 'present':
        color = Colors.green;
        text = 'Present';
        break;
      case 'wfh':
        color = Colors.blue;
        text = 'WFH';
        break;
      case 'onLeave':
      default:
        color = Colors.orange;
        text = 'On Leave';
        break;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12.r)),
      child: Text(text, style: TextStyle(color: color, fontSize: 12.sp, fontWeight: FontWeight.bold)),
    );
  }

  void _showAssignKpiDialog(BuildContext parentContext, TeamMember member) {
    final titleCtrl = TextEditingController();
    final targetCtrl = TextEditingController();
    final role = getIt<SessionCubit>().state;
    final scope = role == UserRole.manager ? ApprovalScope.department : ApprovalScope.team;

    showDialog(
      context: parentContext,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Assign KPI to ${member.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'KPI Title'),
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: targetCtrl,
                decoration: const InputDecoration(labelText: 'Target Value (e.g. 100)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final target = double.tryParse(targetCtrl.text) ?? 100;
                final draft = Kpi(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: titleCtrl.text,
                  description: 'Assigned by manager',
                  departmentObjective: 'Team Goal',
                  targetValue: target,
                  currentValue: 0,
                );
                parentContext.read<TeamKpiCubit>().assignKpi(member.id, draft, scope);
                Navigator.pop(dialogContext);
              },
              child: const Text('Assign'),
            ),
          ],
        );
      },
    );
  }
}
