import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../domain/entities/leave_enums.dart';
import '../bloc/leave_cubit.dart';
import '../bloc/leave_state.dart';
import 'package:hr_app_demo/core/widgets/app_loader.dart';


class LeaveApplyModal extends StatefulWidget {
  const LeaveApplyModal({super.key});
  @override
  State<LeaveApplyModal> createState() => _LeaveApplyModalState();
}

class _LeaveApplyModalState extends State<LeaveApplyModal> {
  LeaveType _type = LeaveType.annual;
  // ignore: prefer_final_fields
  DateTime _start = DateTime.now();
  // ignore: prefer_final_fields
  DateTime _end = DateTime.now().add(const Duration(days: 1));
  final _reason = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocListener<LeaveCubit, LeaveState>(
      listener: (context, state) {
        if (state is LeaveLoaded && state.applySuccess) Navigator.pop(context);
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16.w, right: 16.w, top: 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('apply_leave'.tr(), style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 16.h),
            DropdownButtonFormField<LeaveType>(
              value: _type,
              items: LeaveType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.name.tr()))).toList(),
              onChanged: (v) => setState(() => _type = v!),
              decoration: InputDecoration(labelText: 'leave_type'.tr(), border: const OutlineInputBorder()),
            ),
            SizedBox(height: 16.h),
            TextField(controller: _reason, decoration: InputDecoration(labelText: 'reason'.tr(), border: const OutlineInputBorder())),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: () {
                context.read<LeaveCubit>().applyLeave(_type, _start, _end, false, null, _reason.text, _type == LeaveType.sick);
              },
              child: BlocBuilder<LeaveCubit, LeaveState>(
                builder: (context, state) {
                  return (state is LeaveLoaded && state.isApplying) ? const AppLoader(size: 24) : Text('submit_request'.tr());
                },
              ),
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }
}
