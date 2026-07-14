import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/leave_cubit.dart';
import '../bloc/leave_state.dart';
import 'leave_apply_modal.dart';
import 'package:hr_app_demo/core/widgets/app_loader.dart';


class LeaveOverviewTab extends StatelessWidget {
  const LeaveOverviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LeaveCubit, LeaveState>(
      builder: (context, state) {
        if (state is! LeaveLoaded) return const AppLoader();
        return SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                onPressed: () => showModalBottomSheet(
                  context: context, 
                  isScrollControlled: true, 
                  builder: (_) => BlocProvider.value(value: context.read<LeaveCubit>(), child: const LeaveApplyModal())
                ),
                icon: const Icon(Icons.add),
                label: Text('apply_leave'.tr(), style: TextStyle(fontSize: 16.sp)),
              ),
              SizedBox(height: 24.h),
              Text('leave_overview'.tr(), style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 16.h),
              ...state.balances.map((b) => _BalanceCard(title: b.type.name.tr(), used: b.daysUsed, total: b.daysTotal)),
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
  const _BalanceCard({required this.title, required this.used, required this.total});

  @override
  Widget build(BuildContext context) {
    final left = total - used;
    final progress = total > 0 ? (used / total) : 0.0;
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
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
                Text('$left ${'days'.tr()}', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 12.h),
            LinearProgressIndicator(value: progress, backgroundColor: AppColors.background, color: AppColors.primary, minHeight: 8.h, borderRadius: BorderRadius.circular(4)),
            SizedBox(height: 8.h),
            Text('$used / $total ${'days'.tr()}', style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
