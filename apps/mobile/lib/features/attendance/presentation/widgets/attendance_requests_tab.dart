import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hr_core/features/attendance/domain/entities/overtime_request.dart';
import 'package:hr_app_demo/core/theme/app_colors.dart';
import 'package:hr_app_demo/core/widgets/app_card.dart';
import 'package:hr_app_demo/core/widgets/app_loader.dart';
import '../bloc/attendance_cubit.dart';
import '../bloc/attendance_state.dart';

class AttendanceRequestsTab extends StatefulWidget {
  const AttendanceRequestsTab({super.key});

  @override
  State<AttendanceRequestsTab> createState() => _AttendanceRequestsTabState();
}

class _AttendanceRequestsTabState extends State<AttendanceRequestsTab> {
  final _formKey = GlobalKey<FormState>();
  final _hoursController = TextEditingController();
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _hoursController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
    final hours = double.tryParse(_hoursController.text.trim()) ?? 0;
    final reason = _reasonController.text.trim();
    context.read<AttendanceCubit>().submitOvertime(hours, reason);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AttendanceCubit, AttendanceState>(
      // Listen for success (list updated) → clear form; listen for error → show SnackBar
      listenWhen: (previous, current) {
        if (previous is AttendanceLoaded && current is AttendanceLoaded) {
          // A successful submission updates the overtimeRequests list
          return previous.overtimeRequests.length < current.overtimeRequests.length;
        }
        return current is AttendanceError &&
            current.message == 'overtime_submit_failed';
      },
      listener: (context, state) {
        if (state is AttendanceLoaded) {
          // Success — clear the form fields
          _hoursController.clear();
          _reasonController.clear();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('overtime_submitted_success'.tr()),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 3),
            ),
          );
        } else if (state is AttendanceError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('overtime_submit_error'.tr()),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is! AttendanceLoaded) return const AppLoader();
        final isSubmitting = state.isSubmittingOvertime;

        return SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Submit Form ──────────────────────────────────────────────────
              AppCard(
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'overtime_request'.tr(),
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16.h),
                        TextFormField(
                          controller: _hoursController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'hours'.tr(),
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.timer_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'field_required'.tr();
                            }
                            final hours = double.tryParse(value.trim());
                            if (hours == null || hours <= 0 || hours > 12) {
                              return 'invalid_hours'.tr();
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 12.h),
                        TextFormField(
                          controller: _reasonController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'reason'.tr(),
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.notes_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'field_required'.tr();
                            }
                            if (value.trim().length < 5) {
                              return 'reason_too_short'.tr();
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16.h),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            // Disabled while request is in flight
                            onPressed: isSubmitting ? null : () => _submit(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              disabledBackgroundColor:
                                  AppColors.primary.withValues(alpha: 0.5),
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                            ),
                            child: isSubmitting
                                ? SizedBox(
                                    width: 20.w,
                                    height: 20.w,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'submit'.tr(),
                                    style: TextStyle(
                                        fontSize: 15.sp, color: Colors.white),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: 24.h),

              // ── My Overtime Requests List ─────────────────────────────────────
              Text(
                'my_overtime_requests'.tr(),
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12.h),

              if (state.overtimeRequests.isEmpty)
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.h),
                    child: Text(
                      'no_overtime_requests'.tr(),
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                )
              else
                ...state.overtimeRequests.map((req) => _OvertimeRequestCard(request: req)),
            ],
          ),
        );
      },
    );
  }
}

class _OvertimeRequestCard extends StatelessWidget {
  final OvertimeRequest request;
  const _OvertimeRequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';
    final dateFormat = DateFormat('dd MMM yyyy', context.locale.languageCode);

    final (statusColor, statusLabel) = switch (request.status) {
      OvertimeStatus.approved => (AppColors.success, isArabic ? 'موافق عليه' : 'Approved'),
      OvertimeStatus.rejected => (AppColors.error, isArabic ? 'مرفوض' : 'Rejected'),
      OvertimeStatus.pending => (AppColors.warning, isArabic ? 'قيد المراجعة' : 'Pending'),
    };

    return AppCard(
      margin: EdgeInsets.only(bottom: 10.h),
      child: Padding(
        padding: EdgeInsets.all(14.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hours chip
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Column(
                children: [
                  Text(
                    request.hours.toStringAsFixed(1),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    isArabic ? 'س' : 'hrs',
                    style: TextStyle(fontSize: 10.sp, color: AppColors.primary),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.reason,
                    style:
                        TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    dateFormat.format(request.submittedAt),
                    style: TextStyle(
                        fontSize: 11.sp, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: statusColor.withValues(alpha: 0.4)),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 11.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
