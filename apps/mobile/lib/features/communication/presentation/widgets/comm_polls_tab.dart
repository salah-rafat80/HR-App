import 'package:hr_app_demo/core/widgets/empty_state_widget.dart';
import 'package:hr_app_demo/core/theme/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/communication_cubit.dart';
import '../bloc/communication_state.dart';
import 'package:hr_app_demo/core/widgets/app_loader.dart';
import '../../../../core/widgets/app_card.dart';


class CommPollsTab extends StatelessWidget {
  const CommPollsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CommunicationCubit, CommunicationState>(
      builder: (context, state) {
        if (state is! CommunicationLoaded) return const AppLoader();
        if (state.polls.isEmpty) return const Center(child: Text('No polls available'));

        if (state.polls.isEmpty) return const EmptyStateWidget(icon: AppIcons.modules, message: 'no_data_found');
        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: state.polls.length,
          itemBuilder: (context, index) {
            final poll = state.polls[index];
            final totalVotes = poll.options.fold(0, (sum, o) => sum + o.voteCount);

            return AppCard(
              margin: EdgeInsets.only(bottom: 16.h),
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(poll.question, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
                    SizedBox(height: 16.h),
                    ...poll.options.map((o) {
                      final percent = totalVotes == 0 ? 0.0 : o.voteCount / totalVotes;
                      final isSelected = poll.selectedOptionId == o.id;

                      return GestureDetector(
                        onTap: poll.hasVoted || state.isVoting ? null : () => context.read<CommunicationCubit>().voteInPoll(poll.id, o.id),
                        child: Container(
                          margin: EdgeInsets.only(bottom: 8.h),
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            border: Border.all(color: isSelected ? AppColors.primary : AppColors.background),
                            borderRadius: BorderRadius.circular(8),
                            color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(o.label, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                                  if (poll.hasVoted) Text('${(percent * 100).toInt()}%'),
                                ],
                              ),
                              if (poll.hasVoted) ...[
                                SizedBox(height: 8.h),
                                LinearProgressIndicator(value: percent, backgroundColor: AppColors.background, color: AppColors.primary),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                    if (poll.hasVoted)
                      Padding(
                        padding: EdgeInsets.only(top: 8.h),
                        child: Text('total_votes'.tr(namedArgs: {'count': totalVotes.toString()}), style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary)),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
