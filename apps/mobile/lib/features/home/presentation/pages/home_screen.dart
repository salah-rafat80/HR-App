import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../bloc/home_cubit.dart';
import '../bloc/home_state.dart';
import '../widgets/home_greeting_header.dart';
import '../widgets/home_quick_actions.dart';
import '../widgets/home_status_cards.dart';
import '../widgets/home_announcements_section.dart';
import '../widgets/home_birthdays_section.dart';
import '../widgets/home_holidays_section.dart';
import 'package:hr_app_demo/core/widgets/app_loader.dart';


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<HomeCubit>()..loadDashboard(),
      child: Scaffold(
        body: SafeArea(
          child: BlocBuilder<HomeCubit, HomeState>(
            builder: (context, state) {
              if (state is HomeLoading || state is HomeInitial) {
                return const AppLoader();
              } else if (state is HomeError) {
                return Center(child: Text(state.message));
              } else if (state is HomeLoaded) {
                return RefreshIndicator(
                  onRefresh: () => context.read<HomeCubit>().loadDashboard(),
                  child: ListView(
                    children: [
                      HomeGreetingHeader(name: state.data.employeeName, date: state.data.todayDate, pendingTrainings: state.data.pendingMandatoryTrainingCount),
                      const HomeQuickActions(),
                      HomeStatusCards(
                        leaveLeft: state.data.leaveDaysLeft,
                        leaveTotal: state.data.leaveDaysTotal,
                        kpiScore: state.data.kpiScorePercent,
                        status: state.todayAttendance.status,
                      ),
                      HomeAnnouncementsSection(announcements: state.data.announcements),
                      HomeBirthdaysSection(birthdays: state.data.birthdaysToday),
                      HomeHolidaysSection(holidays: state.data.upcomingHolidays),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}
