import 'package:flutter/material.dart';
import 'package:hr_app_demo/core/theme/app_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/leave_cubit.dart';
import '../bloc/leave_state.dart';
import 'leave_apply_modal.dart';
import 'package:hr_app_demo/core/widgets/app_loader.dart';
import '../../../../core/widgets/app_card.dart';

class LeaveOverviewTab extends StatelessWidget {
  const LeaveOverviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LeaveCubit, LeaveState>(
      builder: (context, state) {
        if (state is LeaveError) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48.w, color: Colors.red),
                  SizedBox(height: 12.h),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  SizedBox(height: 16.h),
                  ElevatedButton(
                    onPressed: () => context.read<LeaveCubit>().loadData(),
                    child: Text('retry'.tr()),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is! LeaveLoaded) return const AppLoader();

        final balances = state.balances;

        return SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => BlocProvider.value(
                    value: context.read<LeaveCubit>(),
                    child: const LeaveApplyModal(),
                  ),
                ),
                icon: const Icon(AppIcons.approve),
                label: Text(
                  'apply_leave'.tr(),
                  style: TextStyle(fontSize: 16.sp),
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                'leave_overview'.tr(),
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16.h),
              if (balances.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 40.h),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 48.w,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          'no_balances_configured_hr'.tr(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...balances.map(
                  (b) => _BalanceCard(
                    title: b.type.name.tr(),
                    used: b.daysUsed,
                    total: b.daysTotal,
                    available: b.availableDays,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final String title;
  final int used;
  final int total;
  final double available;

  const _BalanceCard({
    required this.title,
    required this.used,
    required this.total,
    required this.available,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? (used / total) : 0.0;
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
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
                Text(
                  '$available ${'days'.tr()}',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: AppColors.background,
              color: AppColors.primary,
              minHeight: 8.h,
              borderRadius: BorderRadius.circular(4),
            ),
            SizedBox(height: 8.h),
            Text(
              '$used / $total ${'days'.tr()}',
              style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
