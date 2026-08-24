import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hr_app_demo/core/theme/app_icons.dart';
import 'package:hr_app_demo/core/widgets/empty_state_widget.dart';
import 'package:hr_app_demo/core/widgets/app_loader.dart';
import '../../../../core/bloc/session_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../bloc/communication_cubit.dart';
import '../bloc/communication_state.dart';
import 'new_announcement_modal.dart';

class CommAnnouncementsTab extends StatelessWidget {
  const CommAnnouncementsTab({super.key});

  void _openAddModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<CommunicationCubit>(),
        child: const NewAnnouncementModal(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = context.watch<SessionCubit>().state;
    final role = sessionState.userProfile?.role ?? sessionState.role ?? '';
    final isAuthorizedAdmin = role == 'superAdmin' ||
        role == 'hrAdmin' ||
        role == 'super_admin' ||
        role == 'hr_admin';

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: isAuthorizedAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _openAddModal(context),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: Text(
                'إضافة إعلان',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
            )
          : null,
      body: BlocBuilder<CommunicationCubit, CommunicationState>(
        builder: (context, state) {
          if (state is! CommunicationLoaded) return const AppLoader();
          if (state.announcements.isEmpty) {
            return const EmptyStateWidget(
              icon: AppIcons.modules,
              message: 'no_data_found',
            );
          }

          final df = DateFormat('dd MMM yyyy', context.locale.languageCode);

          return ListView.builder(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 80.h),
            itemCount: state.announcements.length,
            itemBuilder: (context, index) {
              final a = state.announcements[index];
              return AppCard(
                margin: EdgeInsets.only(bottom: 12.h),
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: a.department != null
                                  ? AppColors.secondary.withValues(alpha: 0.1)
                                  : AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              a.department ?? 'company_wide'.tr(),
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                                color: a.department != null
                                    ? AppColors.secondary
                                    : AppColors.primary,
                              ),
                            ),
                          ),
                          Text(
                            df.format(a.date),
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        a.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.sp,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        a.body,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
