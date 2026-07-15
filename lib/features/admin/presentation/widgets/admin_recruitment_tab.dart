import 'package:flutter/material.dart';
import 'package:hr_app_demo/core/theme/app_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../../domain/entities/recruitment_entities.dart';
import '../bloc/recruitment_cubit.dart';
import '../../../../core/widgets/app_card.dart';

class AdminRecruitmentTab extends StatelessWidget {
  const AdminRecruitmentTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<RecruitmentCubit>()..fetchData(),
      child: BlocBuilder<RecruitmentCubit, RecruitmentState>(
        builder: (context, state) {
          if (state is RecruitmentLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is RecruitmentLoaded) {
            return _buildContent(context, state);
          } else if (state is RecruitmentError) {
            return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, RecruitmentLoaded state) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16.w),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showPostJobDialog(context),
              icon: const Icon(AppIcons.approve),
              label: const Text('Post New Job'),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: state.jobs.length,
            itemBuilder: (context, index) {
              final job = state.jobs[index];
              final candidates = state.candidatesMap[job.id] ?? [];
              return AppCard(
                margin: EdgeInsets.only(bottom: 12.h),
                child: ExpansionTile(
                  title: Text(job.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${job.department} • ${candidates.length} Candidates • ${job.openings} Openings'),
                  children: candidates.map((c) => _buildCandidateTile(context, c)).toList(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCandidateTile(BuildContext context, Candidate candidate) {
    return ListTile(
      title: Text(candidate.name),
      subtitle: Text('Stage: ${candidate.stage.name}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (candidate.stage == CandidateStage.offer)
            IconButton(
              icon: Icon(AppIcons.modules, color: AppColors.primary),
              onPressed: () {
                context.read<RecruitmentCubit>().generateOffer(candidate.id);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offer Generated Successfully!')));
              },
            ),
          PopupMenuButton<CandidateStage>(
            onSelected: (newStage) => context.read<RecruitmentCubit>().moveCandidateStage(candidate.id, newStage),
            itemBuilder: (context) => CandidateStage.values.map((s) => PopupMenuItem(value: s, child: Text('Move to ${s.name}'))).toList(),
          ),
        ],
      ),
    );
  }

  void _showPostJobDialog(BuildContext parentContext) {
    final titleCtrl = TextEditingController();
    final deptCtrl = TextEditingController();
    final openingsCtrl = TextEditingController();
    showDialog(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Post New Job'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Job Title')),
            SizedBox(height: 12.h),
            TextField(controller: deptCtrl, decoration: const InputDecoration(labelText: 'Department')),
            SizedBox(height: 12.h),
            TextField(controller: openingsCtrl, decoration: const InputDecoration(labelText: 'Openings'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (titleCtrl.text.isNotEmpty && deptCtrl.text.isNotEmpty) {
                final job = JobRequisition(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: titleCtrl.text,
                  department: deptCtrl.text,
                  status: 'open',
                  openings: int.tryParse(openingsCtrl.text) ?? 1,
                );
                parentContext.read<RecruitmentCubit>().postJob(job);
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Post Job'),
          ),
        ],
      ),
    );
  }
}
