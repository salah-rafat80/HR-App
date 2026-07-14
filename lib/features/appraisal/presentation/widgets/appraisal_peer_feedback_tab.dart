import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/appraisal_cubit.dart';
import '../bloc/appraisal_state.dart';
import 'package:hr_app_demo/core/widgets/app_loader.dart';


class AppraisalPeerFeedbackTab extends StatelessWidget {
  const AppraisalPeerFeedbackTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppraisalCubit, AppraisalState>(
      builder: (context, state) {
        if (state is! AppraisalLoaded) return const AppLoader();
        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: state.peers.length,
          itemBuilder: (context, index) {
            final peer = state.peers[index];
            return Card(
              margin: EdgeInsets.only(bottom: 8.h),
              child: ListTile(
                leading: CircleAvatar(child: Text(peer.colleague.avatarInitial)),
                title: Text(peer.colleague.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
                subtitle: Text(peer.colleague.role, style: TextStyle(fontSize: 12.sp)),
                trailing: Chip(
                  label: Text(peer.submitted ? 'feedback_submitted'.tr() : 'pending_feedback'.tr(), style: const TextStyle(color: Colors.white)),
                  backgroundColor: peer.submitted ? AppColors.success : AppColors.warning,
                ),
                onTap: peer.submitted ? null : () => _showFeedbackDialog(context, peer.colleague.id),
              ),
            );
          },
        );
      },
    );
  }

  void _showFeedbackDialog(BuildContext context, String colleagueId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<AppraisalCubit>(),
        child: AlertDialog(
          title: Text('provide_feedback'.tr()),
          content: TextField(controller: controller, maxLines: 3, decoration: const InputDecoration(border: OutlineInputBorder())),
          actions: [
            TextButton(
              onPressed: () {
                context.read<AppraisalCubit>().submitPeerFeedback(colleagueId, controller.text);
                Navigator.pop(context);
              },
              child: Text('submit'.tr()),
            )
          ],
        ),
      ),
    );
  }
}
