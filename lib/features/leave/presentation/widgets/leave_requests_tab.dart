import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../domain/entities/leave_enums.dart';
import '../bloc/leave_cubit.dart';
import '../bloc/leave_state.dart';
import 'leave_request_detail_modal.dart';
import 'package:hr_app_demo/core/widgets/app_loader.dart';


class LeaveRequestsTab extends StatelessWidget {
  const LeaveRequestsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LeaveCubit, LeaveState>(
      builder: (context, state) {
        if (state is! LeaveLoaded) return const AppLoader();
        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: state.requests.length,
          itemBuilder: (context, index) {
            final req = state.requests[index];
            final df = DateFormat('dd MMM yyyy', context.locale.languageCode);
            return Card(
              margin: EdgeInsets.only(bottom: 8.h),
              child: ListTile(
                onTap: () => showModalBottomSheet(
                  context: context, 
                  isScrollControlled: true, 
                  builder: (_) => BlocProvider.value(value: context.read<LeaveCubit>(), child: LeaveRequestDetailModal(request: req))
                ),
                title: Text(req.type.name.tr(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
                subtitle: Text('${df.format(req.startDate)} - ${df.format(req.endDate)}', style: TextStyle(fontSize: 12.sp)),
                trailing: Chip(
                  label: Text(req.overallStatus.name.tr(), style: TextStyle(fontSize: 10.sp, color: Colors.white)),
                  backgroundColor: _statusColor(req.overallStatus),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _statusColor(LeaveStatus status) {
    if (status == LeaveStatus.approved) return Colors.green;
    if (status == LeaveStatus.rejected) return Colors.red;
    return Colors.orange;
  }
}
