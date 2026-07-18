import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/communication_cubit.dart';
import '../bloc/communication_state.dart';
import 'package:hr_app_demo/core/widgets/app_loader.dart';
import '../../../../core/widgets/app_card.dart';


class CommHandbookTab extends StatelessWidget {
  const CommHandbookTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CommunicationCubit, CommunicationState>(
      builder: (context, state) {
        if (state is! CommunicationLoaded) return const AppLoader();
        if (state.handbook.isEmpty) return const Center(child: Text('Handbook is empty'));

        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: state.handbook.length,
          itemBuilder: (context, index) {
            final section = state.handbook[index];
            return AppCard(
              margin: EdgeInsets.only(bottom: 12.h),
              child: ExpansionTile(
                title: Text(section.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
                children: [
                  Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Text(section.content, style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary, height: 1.5)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
