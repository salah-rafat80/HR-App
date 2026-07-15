import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/di/injection.dart';
import '../bloc/engagement_cubit.dart';
import '../widgets/pulse_survey_card.dart';
import '../widgets/enps_card.dart';
import '../widgets/recognition_feed_card.dart';
import '../widgets/rewards_card.dart';

class EngagementScreen extends StatelessWidget {
  const EngagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<EngagementCubit>()..fetchData(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Engagement'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: BlocBuilder<EngagementCubit, EngagementState>(
          builder: (context, state) {
            if (state is EngagementLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is EngagementLoaded) {
              return RefreshIndicator(
                onRefresh: () => context.read<EngagementCubit>().fetchData(),
                child: ListView(
                  padding: EdgeInsets.all(16.w),
                  children: [
                    PulseSurveyCard(pulse: state.pulse),
                    SizedBox(height: 16.h),
                    EnpsCard(enps: state.enps),
                    SizedBox(height: 16.h),
                    RecognitionFeedCard(feed: state.feed),
                    SizedBox(height: 16.h),
                    RewardsCard(rewards: state.rewards, myPoints: state.myPoints),
                  ],
                ),
              );
            } else if (state is EngagementError) {
              return Center(
                  child: Text(state.message,
                      style: const TextStyle(color: Colors.red)));
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
