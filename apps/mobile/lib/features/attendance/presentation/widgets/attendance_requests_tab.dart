import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AttendanceRequestsTab extends StatelessWidget {
  const AttendanceRequestsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('overtime_request'.tr(), style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 16.h),
          TextField(decoration: InputDecoration(labelText: 'hours'.tr(), border: const OutlineInputBorder())),
          SizedBox(height: 16.h),
          TextField(decoration: InputDecoration(labelText: 'reason'.tr(), border: const OutlineInputBorder())),
          SizedBox(height: 16.h),
          ElevatedButton(onPressed: () {}, child: Text('submit'.tr())),
        ],
      ),
    );
  }
}
