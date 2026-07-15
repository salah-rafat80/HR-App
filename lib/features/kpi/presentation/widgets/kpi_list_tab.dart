import 'package:hr_app_demo/core/widgets/empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/kpi_entities.dart';
import '../bloc/kpi_cubit.dart';
import '../bloc/kpi_state.dart';
import 'kpi_detail_modal.dart';
import 'package:hr_app_demo/core/widgets/app_loader.dart';
import '../../../../core/widgets/app_card.dart';


class KpiListTab extends StatelessWidget {
  const KpiListTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<KpiCubit, KpiState>(
      builder: (context, state) {
        if (state is! KpiLoaded) return const AppLoader();
        if (state.kpis.isEmpty) return const EmptyStateWidget(icon: Icons.inbox, message: 'no_data_found');
        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: state.kpis.length,
          itemBuilder: (context, index) {
            final kpi = state.kpis[index];
            return _KpiCard(kpi: kpi);
          },
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  final Kpi kpi;
  const _KpiCard({required this.kpi});

  @override
  Widget build(BuildContext context) {
    final progress = kpi.progressPercent;
    final color = progress < 0.5 ? AppColors.error : (progress < 0.8 ? AppColors.warning : AppColors.success);
    
    return AppCard(
      margin: EdgeInsets.only(bottom: 12.h),
      child: InkWell(
        onTap: () => showModalBottomSheet(
          context: context, 
          isScrollControlled: true, 
          builder: (_) => BlocProvider.value(value: context.read<KpiCubit>(), child: KpiDetailModal(kpi: kpi))
        ),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(kpi.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
              SizedBox(height: 4.h),
              Text(kpi.departmentObjective, style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary)),
              SizedBox(height: 12.h),
              LinearProgressIndicator(value: progress > 1 ? 1 : progress, backgroundColor: AppColors.background, color: color, minHeight: 8.h, borderRadius: BorderRadius.circular(4)),
              SizedBox(height: 8.h),
              Text('${(progress * 100).toInt()}%', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
