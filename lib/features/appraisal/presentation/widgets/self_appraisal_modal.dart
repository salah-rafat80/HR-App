import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/appraisal_cubit.dart';
import '../bloc/appraisal_state.dart';
import 'package:hr_app_demo/core/widgets/app_loader.dart';


class SelfAppraisalModal extends StatefulWidget {
  const SelfAppraisalModal({super.key});

  @override
  State<SelfAppraisalModal> createState() => _SelfAppraisalModalState();
}

class _SelfAppraisalModalState extends State<SelfAppraisalModal> {
  final Map<String, TextEditingController> _controllers = {};

  @override
  void dispose() {
    for (var c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AppraisalCubit, AppraisalState>(
      listener: (context, state) {
        if (state is AppraisalLoaded && state.submitSuccess) Navigator.pop(context);
      },
      builder: (context, state) {
        if (state is! AppraisalLoaded) return const SizedBox.shrink();
        final score = (state.currentKpiScore * 100).toInt();
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.w),
                color: AppColors.secondary.withValues(alpha: 0.1),
                child: Text('kpi_average_banner'.tr(namedArgs: {'score': score.toString()}), 
                  textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary)),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.all(16.w),
                  itemCount: state.questions.length,
                  itemBuilder: (context, index) {
                    final q = state.questions[index];
                    _controllers.putIfAbsent(q.id, () => TextEditingController());
                    return Padding(
                      padding: EdgeInsets.only(bottom: 16.h),
                      child: TextField(
                        controller: _controllers[q.id],
                        maxLines: 2,
                        decoration: InputDecoration(labelText: q.questionText, border: const OutlineInputBorder()),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16.w),
                child: ElevatedButton(
                  onPressed: () {
                    final answers = state.questions.map((q) => q.copyWith(answerText: _controllers[q.id]?.text)).toList();
                    context.read<AppraisalCubit>().submitSelfAppraisal(answers);
                  },
                  child: state.isSubmitting ? const AppLoader(size: 24) : Text('submit'.tr()),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
