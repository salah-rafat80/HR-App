import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/training_cubit.dart';
import '../bloc/training_state.dart';
import 'package:hr_app_demo/core/widgets/app_loader.dart';


class TrainingCertificationsTab extends StatelessWidget {
  const TrainingCertificationsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TrainingCubit, TrainingState>(
      builder: (context, state) {
        if (state is! TrainingLoaded) return const AppLoader();
        if (state.certifications.isEmpty) return const Center(child: Text('No certifications yet'));

        final df = DateFormat('dd MMM yyyy', context.locale.languageCode);

        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: state.certifications.length,
          itemBuilder: (context, index) {
            final cert = state.certifications[index];
            return Card(
              margin: EdgeInsets.only(bottom: 12.h),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.success.withValues(alpha: 0.1),
                  child: const Icon(Icons.verified, color: AppColors.success),
                ),
                title: Text(cert.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
                subtitle: Text('earned_on'.tr(namedArgs: {'date': df.format(cert.dateEarned)}), style: TextStyle(fontSize: 12.sp)),
              ),
            );
          },
        );
      },
    );
  }
}
