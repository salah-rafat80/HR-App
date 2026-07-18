import 'package:flutter/material.dart';
import 'package:hr_app_demo/core/theme/app_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:hr_core/features/kpi/domain/entities/kpi_entities.dart';
import '../bloc/kpi_cubit.dart';
import '../bloc/kpi_state.dart';

class KpiDetailModal extends StatefulWidget {
  final Kpi kpi;
  const KpiDetailModal({super.key, required this.kpi});

  @override
  State<KpiDetailModal> createState() => _KpiDetailModalState();
}

class _KpiDetailModalState extends State<KpiDetailModal> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = widget.kpi.selfAssessmentText ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<KpiCubit, KpiState>(
      builder: (context, state) {
        if (state is! KpiLoaded) return const SizedBox.shrink();
        final kpi = state.kpis.firstWhere((k) => k.id == widget.kpi.id, orElse: () => widget.kpi);
        
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16.w, right: 16.w, top: 24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(kpi.title, style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 8.h),
              Text(kpi.description, style: TextStyle(fontSize: 14.sp)),
              SizedBox(height: 16.h),
              Text('${'department_objective'.tr()}: ${kpi.departmentObjective}', style: TextStyle(fontSize: 12.sp, color: AppColors.primary, fontStyle: FontStyle.italic)),
              SizedBox(height: 16.h),
              TextField(controller: _controller, maxLines: 3, decoration: InputDecoration(labelText: 'self_assessment'.tr(), hintText: 'type_assessment'.tr(), border: const OutlineInputBorder())),
              SizedBox(height: 16.h),
              if (kpi.selfAssessmentText != null && kpi.selfAssessmentText!.isNotEmpty)
                Align(alignment: Alignment.centerRight, child: Chip(label: Text('submitted_tick'.tr(), style: const TextStyle(color: Colors.white)), backgroundColor: AppColors.success)),
              ElevatedButton(onPressed: () => context.read<KpiCubit>().submitAssessment(kpi.id, _controller.text), child: Text('submit_assessment'.tr())),
              SizedBox(height: 16.h),
              TextButton.icon(
                onPressed: () => context.read<KpiCubit>().attachEvidence(kpi.id),
                icon: const Icon(AppIcons.modules),
                label: Text(kpi.hasEvidence ? 'evidence_attached'.tr() : 'attach_evidence'.tr()),
              ),
              SizedBox(height: 24.h),
            ],
          ),
        );
      },
    );
  }
}
