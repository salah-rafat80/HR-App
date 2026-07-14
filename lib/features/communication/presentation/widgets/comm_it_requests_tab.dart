import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/it_request_entities.dart';
import '../bloc/communication_cubit.dart';
import '../bloc/communication_state.dart';
import 'new_it_request_modal.dart';
import 'package:hr_app_demo/core/widgets/app_loader.dart';


class CommItRequestsTab extends StatelessWidget {
  const CommItRequestsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CommunicationCubit, CommunicationState>(
      builder: (context, state) {
        if (state is! CommunicationLoaded) return const AppLoader();

        final df = DateFormat('dd MMM yyyy', context.locale.languageCode);

        return Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16.w),
              child: ElevatedButton(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => BlocProvider.value(
                    value: context.read<CommunicationCubit>(),
                    child: const NewItRequestModal(),
                  ),
                ),
                child: Text('new_it_request'.tr()),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                itemCount: state.itRequests.length,
                itemBuilder: (context, index) {
                  final req = state.itRequests[index];
                  return Card(
                    margin: EdgeInsets.only(bottom: 12.h),
                    child: ListTile(
                      title: Text(req.id, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(req.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                          SizedBox(height: 4.h),
                          Text(df.format(req.submittedDate), style: TextStyle(fontSize: 10.sp, color: AppColors.textSecondary)),
                        ],
                      ),
                      trailing: _buildStatusChip(req.status),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusChip(ItRequestStatus status) {
    String label;
    Color color;
    switch (status) {
      case ItRequestStatus.open: label = 'status_open'.tr(); color = AppColors.warning; break;
      case ItRequestStatus.inProgress: label = 'status_in_progress'.tr(); color = AppColors.primary; break;
      case ItRequestStatus.resolved: label = 'status_resolved'.tr(); color = AppColors.success; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(color: color, fontSize: 10.sp, fontWeight: FontWeight.bold)),
    );
  }
}
